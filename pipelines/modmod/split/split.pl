use strict;
use warnings;

# find and annotate high-quality concatemerized oligo chunks in a training read stream

# initialize reporting
our $script = "split";
our $error  = "$script error";
my ($nInputReads) = (0) x 20;

# load dependencies
my $perlUtilDir = "$ENV{GENOMEX_MODULES_DIR}/utilities/perl";
map { require "$perlUtilDir/$_.pl" } qw(workflow numeric);
our ($matchScore, $mismatchPenalty, $gapOpenPenalty, $gapExtensionPenalty) = 
    (1,           -1.5,             -1.5,            -2);
map { require "$perlUtilDir/sequence/$_.pl" } qw(general smith_waterman);
resetCountFile();

# environment variables
fillEnvVar(\our $TASK_DIR,              'TASK_DIR');
fillEnvVar(\our $N_CPU,                 'N_CPU');
fillEnvVar(\our $FLANK_LEFT,            'FLANK_LEFT');
fillEnvVar(\our $CHUNK,                 'CHUNK'); # models may use more than one modification of the same canonical base
fillEnvVar(\our $FLANK_RIGHT,           'FLANK_RIGHT');
fillEnvVar(\our $MODIFICATION_INDICES,  'MODIFICATION_INDICES'); # all indices must be the same size
fillEnvVar(\our $MAX_PENALTY,           'MAX_PENALTY');
fillEnvVar(\our $LENGTH_PADDING,        'LENGTH_PADDING');
fillEnvVar(\our $MAX_READ_LENGTH,       'MAX_READ_LENGTH');
fillEnvVar(\our $MAX_CHUNKS_PER_THREAD, 'MAX_CHUNKS_PER_THREAD');
fillEnvVar(\our $MIN_SCORE_DELTA,       'MIN_SCORE_DELTA');
fillEnvVar(\our $BAM_FILES,             'BAM_FILES');
fillEnvVar(\our $FOCUS_POSITIONS_FILE,  'FOCUS_POSITIONS_FILE');

# parse the modification indices
print STDERR "\n";
my (%mods, $modLengthCheck, $FLANK_RIGHT_LENGTH);
foreach my $x(split(",", $MODIFICATION_INDICES)){
    my ($baseName, $index) = split(":", $x);
    $mods{$index} = {
        baseName   => $baseName,
        index      => $index,
        directory  => "$TASK_DIR/bam_$baseName",
        filePrefix => "$TASK_DIR/bam_$baseName/$baseName",
        flankRight => "$FLANK_RIGHT$index"
    };
    if($modLengthCheck){
         length($index) == $modLengthCheck or die "canonical/modified base indices must all be the same length\n";
    } else {
        $modLengthCheck = length($index);
        $FLANK_RIGHT_LENGTH = length($mods{$index}{flankRight});
    }
    print STDERR "$baseName unit = $FLANK_LEFT$CHUNK$mods{$index}{flankRight}\n";
    !-d $mods{$index}{directory} and mkdir $mods{$index}{directory};
    unlink glob("$mods{$index}{directory}/*"); # clear any remnants from prior failed runs
}

# parse the oligo configuration
my $FLANK_LEFT_LENGTH = length($FLANK_LEFT);
my $CHUNK_LENGTH      = length($CHUNK);
$CHUNK_LENGTH % 2 == 1 or die "randomized interrogation chunk must have an odd number of bases\n";

# set the thresholds
my $MIN_SCORE_LEFT  = $FLANK_LEFT_LENGTH  - $MAX_PENALTY;
my $MIN_SCORE_RIGHT = $FLANK_RIGHT_LENGTH - $MAX_PENALTY;
my $OLIGO_LENGTH = $FLANK_LEFT_LENGTH + $CHUNK_LENGTH + $FLANK_RIGHT_LENGTH; # excludes the ligation overhangs
my $OLIGO_SEARCH_LENGTH = $OLIGO_LENGTH + $LENGTH_PADDING;
my $FOCUS_BASE_INDEX = ($CHUNK_LENGTH - 1) / 2;
my $FOCUS_BASE = substr($CHUNK, $FOCUS_BASE_INDEX, 1);

# log file feedback
print STDERR "OLIGO_LENGTH = $OLIGO_LENGTH\n";
print STDERR "CHUNK_LENGTH = $CHUNK_LENGTH\n";
print STDERR "FOCUS_BASE = $FOCUS_BASE\n\n";

# generate the required bam file header and focus positions BED file
# one "chromosome" per possible context chunk
# TODO: as an alternative, could probably used a single "chromosome" of length $CHUNK_LENGTH
#       always set MD:Z:$CHUNK_LENGTH and run remora with option --basecall-anchor (or, probably not even that)
open my $focusRefPosH, ">", $FOCUS_POSITIONS_FILE or die "could not open $FOCUS_POSITIONS_FILE: $!\n";
my $bamHeader = "\@HD\tVN:1.6\tSO:unsorted\n";
my @flankMers = glob "{A,C,G,T}" x $FOCUS_BASE_INDEX;
foreach my $leftFlank(@flankMers){
    foreach my $rightFlank(@flankMers){
        # TODO: honor IUPAC codes in randomer, e.g., V instead of N?
        # probably not necessary, would mostly server to reduce the size of the sequence dictionary
        my $chunk = "$leftFlank$FOCUS_BASE$rightFlank";
        $bamHeader .= "\@SQ\tSN:$chunk\tLN:$CHUNK_LENGTH\n";
        print $focusRefPosH join("\t", $chunk, $FOCUS_BASE_INDEX, $FOCUS_BASE_INDEX + 1), "\n";
    }
}
close $focusRefPosH;

# set file formats
use constant {
    QNAME => 0, # SAM fields
    FLAG => 1,
    RNAME => 2,
    POS => 3,
    MAPQ => 4,
    CIGAR => 5,
    RNEXT => 6,
    PNEXT => 7,
    TLEN => 8,
    SEQ => 9,
    QUAL => 10,
    TAGS => 11,
    #---------------
    QRY_START_ => 1,
    QRY_END_ => 2
};

# run individual reads in series, distribute processing to parallel threads
launchChildThreads(\&processRead);
use vars qw(@readH @writeH);
my $writeH = $writeH[1];
my @bamFiles = split(" ", $BAM_FILES);
print STDERR "processing ".commify(scalar(@bamFiles))." input ubam files\n\n";
foreach my $bamFile(@bamFiles){
    print STDERR "$bamFile: ".commify($nInputReads)." reads processed\n";
    open my $inH, "-|", "slurp samtools view $bamFile" or die "could not open: $bamFile: $1\n";
    while (my $read = <$inH>){
        $nInputReads++;
        $writeH = $writeH[$nInputReads % $N_CPU + 1];
        print $writeH $read;
    }
    close $inH;
}
finishChildThreads();

# print summary information
print STDERR "\n";
printCount($nInputReads, 'nInputReads', 'input nanopore reads');

# the child thread function for processing reads
our ($nThreadChunks, $flag, %chunkBases, %nThreadChunks) = (0);
sub processRead {
    my ($childN) = @_;

    # initialize thread
    $nThreadChunks = 0;
    %chunkBases = map { 
        $mods{$_}{baseName} => [map {
            {A => 0, C => 0, G => 0, T => 0}
        } 0..($CHUNK_LENGTH - 1)]
    } keys %mods;

    # open output file handles for this thread
    foreach my $index(keys %mods){
        open my $bamH, "|-", "samtools view -b - | slurp -s 50M -o $mods{$index}{filePrefix}.$childN.bam" or 
            die "could not open bam output stream: $!\n";
        $mods{$index}{bamH} = $bamH;
        print $bamH $bamHeader;
    }

    # process reads one at a time
    my $readH = $readH[$childN];
    while(my $read = <$readH>){
        $nThreadChunks >= $MAX_CHUNKS_PER_THREAD and next;
        chomp $read;
        my @read = split("\t", $read, 12);
        my $readLength = length($read[SEQ]);
        $readLength > $MAX_READ_LENGTH and next;
        $flag = 0;
        searchReadSegmentForUnitOligo(\@read, $readLength, 0, $readLength, 1);
    }

    # close file handles
    foreach my $index(keys %mods){
        my $bamH = $mods{$index}{bamH};
        close $bamH;
    }

    # report results from this thread
    print STDERR "\nthread $childN summary:\n";
    print STDERR "total chunks committed: ".commify($nThreadChunks)."\n";
    foreach my $baseName(sort keys %nThreadChunks){
        print STDERR "   $baseName chunks committed: ".commify($nThreadChunks{$baseName})."\n";
    }
    foreach my $baseName(sort keys %chunkBases){
        print STDERR "$baseName chunk base usage:\n";
        print STDERR join("\t", qw(A C G T)), "\n";
        foreach my $i(0..($CHUNK_LENGTH - 1)){
            print STDERR join("\t", map { $chunkBases{$baseName}[$i]{$_} } qw(A C G T)), "\n";
        }
    }
}

# recursively break a read into oligo segments until no more are found
sub searchReadSegmentForUnitOligo {
    my ($read, $readLength, $startI0, $endI1, $isWholeRead) = @_;

    # extract the working segment of the read
    my $segmentLength = $endI1 - $startI0;
    $segmentLength >= $OLIGO_LENGTH or return; # end the recursion when insufficient sequence remains
    my $readSegment = $isWholeRead ? $$read[SEQ] : substr($$read[SEQ], $startI0, $segmentLength);

    # attempt to find a high-quality match to the left flank
    my ($qryOnRefLeft, $scoreLeft, $startQryLeft0, $endQryLeft0, $startRefLeft0, $endRefLeft0) = 
        smith_waterman($FLANK_LEFT, $readSegment, undef, QRY_END_); # require alignment to the end of the flank nearest the chunk, here to the right

    # if no left match is found, end the recursion; no smaller segments could succeed
    $scoreLeft >= $MIN_SCORE_LEFT or return; 

    # restrict the search space for the candidate oligo unit when looking for the right flank
    $startRefLeft0 += $startI0;
    $endRefLeft0   += $startI0;
    my $candidateEnd1 = min($startRefLeft0 + $OLIGO_SEARCH_LENGTH, $readLength);
    $readSegment = substr($$read[SEQ], $startRefLeft0, $candidateEnd1 - $startRefLeft0);

    # attempt to find a high-quality match to the right flank
    my %bestHit = (score => 0);
    my @rightScores = (0); # thus, guarantee at least two scores, even if user if only modeling one base type
    foreach my $index(keys %mods){
        my ($qryOnRef, $score, $startQry0, $endQry0, $startRef0, $endRef0) = 
            smith_waterman($mods{$index}{flankRight}, $readSegment, undef, QRY_START_);
        push @rightScores, $score;
        if($score > $MIN_SCORE_RIGHT and $score > $bestHit{score}){
            %bestHit = (
                index => $index,
                score => $score,
                startRefRight0 => $startRef0 + $startRefLeft0,
                endRefRight0   => $endRef0   + $startRefLeft0
            );
        }
    }
    @rightScores = sort { $b <=> $a } @rightScores;

    # if no usable right match is found, recurse the segments by splitting on the found flank left
    my $scoreDelta = $rightScores[0] - $rightScores[1];
    ($bestHit{score} >= $MIN_SCORE_RIGHT and $scoreDelta >= $MIN_SCORE_DELTA) or 
        return searchSplitSegmentForUnitOligo($read, $readLength, $startI0, $startRefLeft0, $endRefLeft0, $endI1);

    # check the chunk size and focus base
    # be strict, must exactly match the expected chunk size and focus base so that we trust the chunk base calls
    my $chunkSize = $bestHit{startRefRight0} - $endRefLeft0 - 1;
    my $focusBase = substr($$read[SEQ], $endRefLeft0 + 1 + $FOCUS_BASE_INDEX, 1);
    $chunkSize == $CHUNK_LENGTH and $focusBase eq $FOCUS_BASE and 
        commitChunk($read, $readLength, $endRefLeft0, \%bestHit, $scoreDelta);

    # regardless of whether chunk was committed, continue checking the flanks of the found oligo unit
    searchSplitSegmentForUnitOligo($read, $readLength, $startI0, $startRefLeft0, $bestHit{endRefRight0}, $endI1);
}

# after a successful find of even a partial oligo after a search of a complete segment
# split the segment into its two flanking sides (excluding the prior match) and check them again recursively
sub searchSplitSegmentForUnitOligo {
    my ($read, $readLength, $leftStart, $leftEnd, $rightStart, $rightEnd) = @_;
    searchReadSegmentForUnitOligo($read, $readLength, $leftStart,  $leftEnd);
    searchReadSegmentForUnitOligo($read, $readLength, $rightStart, $rightEnd);
}

# commit the alignment for a found oligo unit
sub commitChunk {
    my ($read, $readLength, $endRefLeft0, $bestHit, $scoreDelta) = @_;
    my @read = @$read; # make a hard copy so that TAGS is renewed each time
    my $mod = $mods{$$bestHit{index}};

    # get the canonical bases of the chunk, as called by Dorado
    my $chunkStart0 = $endRefLeft0 + 1;
    my $chunk = substr($read[SEQ], $chunkStart0, $CHUNK_LENGTH);

    # update the bam read to an alignment
    # leave as is: QNAME, RNEXT, PNEXT, SEQ, QUAL
    # TODO: will Remora process supplemental alignments? if not, can they all be left as primary?
    $read[FLAG]    = $flag;  # set to 0 (first alignment from a read) or 2048 (for all additional supplemental alignments)
    $read[RNAME]   = $chunk; # thus, the "chromosome" is the base context
    $read[POS]     = 1;      # always aligned to the first base of that "chromosome"
    $read[MAPQ]    = 60;     # assert high quality, probably not used by remora
    $read[CIGAR]   = $chunkStart0."S".$CHUNK_LENGTH."M".($readLength - $$bestHit{startRefRight0})."S";
    $read[TLEN]    = $readLength;
    $read[TAGS]   .= "\t".join("\t",
        "MD:Z:$CHUNK_LENGTH",
        "XN:Z:$$mod{baseName}",
        "XR:i:$$bestHit{score}", # the score on the right side for the selected base type
        "XD:i:$scoreDelta"       # the differential of that score to the next best base type
    );

    # print the alignment to the appropriate bam file
    my $bamH = $$mod{bamH};
    print $bamH join("\t", @read), "\n";
    $nThreadChunks++;
    $nThreadChunks{$$mod{baseName}}++;

    # record the chunk bases for assessing base randomness
    my @chunk = split("", $chunk);
    foreach my $i(0..($CHUNK_LENGTH - 1)){
        $chunkBases{$$mod{baseName}}[$i]{$chunk[$i]}++
    }

    # prepare for subsequent supplemental alignments
    $flag = 2048;
}

# an example unaligned bam read from Dorado basecaller
# 00c75e7f-449c-42c6-80f2-65bff27255c5    
# 4       
# *       
# 0       
# 0       
# *       
# *       
# 0       
# 0       
# GTGCGTCTACTTGGTTCAAGTTCGTTTGTGCTGTACAAGACTACTCAGCCAATCACCACTGAAGCCCACGTCGTCGAGCGTCACGAACTACTTCACCAATCACGTGATGATTGCTACCACATCATCCTGCCGTCACGAACTCAGCCAATCACAGCCTCACCGCCTACCACATCATCAGAGCGTCACGAACTACTCGGCCGTCCGCGGTAATGCCTACCACATCCTGCAGTCGCGAGTTCTTCAGCCAATCGCTCGATGATCACCTCACGG        
# $$$%$$$$$(+/-/000-*(()/-+*)'')**0/))%$$&%'&('''*+++***,010/0)'''+0/,.&&&&&&&'((,000177777.)('()()'())*//019:8888664221//'(((*778<80----1531..)))***,--.745667:==1/...=BB1111299861014/.../(('''-487)(((&$$$$&&&'''*)*3328821))(*+,+(('(())&%$$$$%%&&))+++)'(((,11.-.-,,+*)--+*        
# qs:i:9  
# du:f:0.8066     
# ns:i:4033       
# ts:i:10 
# mx:i:4ch:i:2046        
# st:Z:2024-01-11T14:24:08.580+00:00      
# rn:i:133264     
# fn:Z:PAU55465_pass_2cc000b9_2716601c_10044.pod5 
# sm:f:-766.172   
# sd:f:0.00798761        
# sv:Z:pa 
# dx:i:0  
# RG:Z:2716601c12d86c9728aad96652680b124dd018a7_dna_r10.4.1_e8.2_400bps_sup@v4.3.0        
# mv:B:c,6,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,1,1,0,0,1,1,0,0,0,0,1,0,1,1,0,1,0,0,1,0,0,1,0,1,1,0,0,0,0,1,0,1,1,0,0,0,0,1,1,0,1,0,1,1,1,1,0,1,0,0,0,0,0,1,0,1,0,0,0,0,1,0,1,1,0,0,0,1,1,0,1,1,0,0,0,1,1,1,0,1,0,1,1,1,1,1,0,1,1,0,1,0,1,0,1,0,0,1,1,0,1,0,0,0,0,0,0,0,0,1,0,0,1,1,0,1,0,1,0,1,0,1,0,0,0,0,0,0,1,0,0,1,1,0,0,0,0,0,1,1,0,0,0,0,0,0,1,0,1,0,0,0,1,0,1,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,1,1,1,0,0,0,0,1,0,0,1,1,0,1,1,0,0,1,1,0,0,1,0,1,1,0,0,1,1,0,0,1,1,1,0,1,1,1,1,0,0,0,1,1,0,1,0,0,1,1,0,0,1,1,0,0,0,1,0,1,1,0,1,0,1,0,1,0,0,1,1,0,0,0,0,0,1,0,1,1,0,1,0,0,0,1,0,0,1,1,0,0,1,0,1,0,1,0,1,0,1,0,0,0,1,1,0,0,1,1,0,1,0,0,0,0,1,0,1,1,0,0,0,0,0,0,0,0,0,1,0,1,0,0,1,0,0,1,1,0,1,0,0,0,0,1,1,0,1,1,0,1,0,1,1,0,0,0,1,1,0,1,1,0,1,0,1,1,1,0,1,0,1,1,1,0,1,1,0,1,1,0,1,1,1,0,1,0,1,0,1,0,1,0,1,0,0,1,1,0,1,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,1,1,0,0,1,1,1,0,0,0,0,0,0,0,1,0,1,0,1,0,0,0,0,0,0,1,0,0,0,1,1,0,0,1,1,0,0,1,0,0,0,0,0,1,1,0,1,0,1,0,1,1,0,0,0,1,0,0,0,1,0,1,1,0,0,1,0,0,1,0,0,0,1,1,0,1,0,0,0,1,0,1,0,0,0,1,1,1,0,1,0,0,1,0,0,1,1,0,0,0,1,1,0,1,0,1,1,0,1,1,0,1,0,1,1,0,1,1,0,0,1,1,0,0,0,0,1,1,0,1,0,1,0,1,0,1,1,1,0,1,0,1,1,0,0,0,1,1,0,0,1,0,1,1,0,0,0,1,1,0,1,0,0,0,0,1,0,1,0,0,0,1,0,1,0,0,0,1,0,0,0,0,0,0,0,1,0,1,1,0,0,0,0,1,0,0,1,1,1,0,0,0,1,0,1,0,1,1,0,0,0,0,1,1,1,0,0,0,0,1,0,1,1,0,1,1,0,0,0,1,0,0,0,1,1,0,1,0,0

# $ remora dataset prepare --help
# usage: remora dataset prepare [...] pod5 bam

# Prepare a core Remora dataset

# positional arguments:
#   pod5                  POD5 (file or directory) matched to bam file.
#   bam                   BAM file containing mv tags.

# Output Arguments:
#   --output-path OUTPUT_PATH
#                         Output Remora training dataset directory. Cannot exist unless --overwrite is specified in which case the directory
#                         will be removed. (default: remora_training_dataset)
#   --overwrite           Overwrite existing output directory if existing. (default: False)

# Data Arguments:
#   --motif MOTIF FOCUS_POSITION
#                         Motif at which the produced model is applicable. If --focus-reference-positions is not provided chunks will be
#                         extracted from motif positions as well. Argument takes 2 values representing 1) sequence motif and 2) focus position
#                         within the motif. For example to restrict to CpG sites use --motif CG 0". (default: None)
#   --focus-reference-positions FOCUS_REFERENCE_POSITIONS
#                         BED file containing reference positions around which to extract training chunks. (default: None)
#   --chunk-context NUM_BEFORE NUM_AFTER
#                         Number of context signal points to select around the central position. (default: (200, 200))
#   --min-samples-per-base MIN_SAMPLES_PER_BASE
#                         Minimum number of samples per base. This sets the size of the ragged arrays of chunk sequences. (default: 5)
#   --kmer-context-bases BASES_BEFORE BASES_AFTER
#                         Definition of k-mer (derived from the reference) passed into the model along with each signal position. (default: (4,
#                         4))
#   --max-chunks-per-read MAX_CHUNKS_PER_READ
#                         Maxiumum number of chunks to extract from a single read. (default: 15)
#   --base-start-justify  Justify extracted chunk against the start of the base of interest. Default justifies chunk to middle of signal of the
#                         base of interest. (default: False)
#   --offset OFFSET       Offset selected chunk position by a number of bases. (default: 0)
#   --num-reads NUM_READS
#                         Number of reads. (default: None)
#   --basecall-anchor     Make dataset from basecall sequence instead of aligned reference sequence (default: False)
#   --skip-shuffle        Skip shuffle of completed dataset. Note that shuffling requires loading the entire signal array into memory. If
#                         dataset is very large and shuffling is not required specify this flag. (default: False)

# Label Arguments:
#   --mod-base SHORT_NAME LONG_NAME
#                         Modified base information. The short name should be a single letter modified base code or ChEBI identifier as defined
#                         in the SAM tags specificaions. The long name may be any longer identifier. Example: `--mod-base m 5mC` (default:
#                         None)
#   --mod-base-control    Is this a modified bases control sample? (default: False)
