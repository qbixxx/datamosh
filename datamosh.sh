#!/bin/bash

set -o errexit

WORKING_DIR="datamosh_artifacts"
LOG_FILE="datamosh.log"
> "$LOG_FILE"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    echo "[INFO] $1" >> "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    echo "[SUCCESS] $1" >> "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "[WARNING] $1" >> "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    echo "[ERROR] $1" >> "$LOG_FILE"
}

log_debug() {
    if [ "$DEBUG_MODE" = true ]; then
        echo -e "${CYAN}[DEBUG]${NC} $1"
    fi
    echo "[DEBUG] $1" >> "$LOG_FILE"
}

PROFILES=(
    "glitch:3:0.03:100:2:720:480"
    "bloom:2:0.05:150:3:640:480"
    "smear:4:0.01:300:2:854:480"
    "extreme:1:0.005:500:6:1280:720"
    "rainbow:2:0.02:80:8:640:360"
)

DEBUG_MODE=false
GIF_OUTPUT=false
GIF_DURATION=5
GIF_FPS=10
ACTIVE_PROFILE=""

check_dependencies() {
    log_info "Checking dependencies..."
    missing_deps=()
    command -v ffmpeg &> /dev/null || missing_deps+=("ffmpeg")
    command -v bc &> /dev/null || missing_deps+=("bc")
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing: ${missing_deps[*]}"
        log_info "Install with: sudo apt-get install ${missing_deps[*]}"
        exit 1
    fi
    log_success "All dependencies present"
}

init_environment() {
    mkdir -p "$WORKING_DIR"
    log_info "Initialized at $(date)"
    log_info "Command: $0 $*"
}

apply_profile() {
    profile_name="$1"
    profile_found=false
    for profile in "${PROFILES[@]}"; do
        name=$(echo $profile | cut -d':' -f1)
        if [ "$name" == "$profile_name" ]; then
            profile_data=$profile
            profile_found=true
            break
        fi
    done
    if [ "$profile_found" == "false" ]; then
        log_error "Profile not found: $profile_name"
        echo "Available profiles: glitch, bloom, smear, extreme, rainbow"
        exit 1
    fi
    Q_VAL=$(echo $profile_data | cut -d':' -f2)
    DAMAGE_OFFSET_PCT=$(echo $profile_data | cut -d':' -f3)
    DAMAGE_SIZE=$(echo $profile_data | cut -d':' -f4)
    DAMAGE_COUNT=$(echo $profile_data | cut -d':' -f5)
    RESOLUTION=$(echo $profile_data | cut -d':' -f6,7)
    log_info "Applied profile: $profile_name"
    ACTIVE_PROFILE=$profile_name
}

validate_inputs() {
    [ -f "$INPUT_FILE_1" ] || { log_error "File not found: $INPUT_FILE_1"; exit 1; }
    [ -f "$INPUT_FILE_2" ] || { log_error "File not found: $INPUT_FILE_2"; exit 1; }
    output_dir=$(dirname "$OUTPUT_FILE")
    if [ "$output_dir" != "." ] && [ ! -d "$output_dir" ]; then
        log_warning "Creating output directory: $output_dir"
        mkdir -p "$output_dir"
    fi
    if [ -z "$ACTIVE_PROFILE" ] && ! [[ "$INTENSITY" =~ ^[1-5]$ ]]; then
        log_error "Invalid intensity: $INTENSITY (1-5)"
        exit 1
    fi
    log_success "Input validation complete"
}

show_help() {
    echo -e "${MAGENTA}Datamosh${NC} - Video Glitch Tool v1.2.0"
    echo "Usage: ./datamosh.sh [options] input1.mp4 input2.mp4 [output.mp4] [intensity]"
    echo "Options:"
    echo "  --help, -h        Show help"
    echo "  --debug, -d       Enable debug mode"
    echo "  --check-deps      Check required dependencies"
    echo "  --profile, -e     Apply effect profile"
    echo "  --gif, -g [dur] [fps]  Create GIF (default 5s, 10fps)"
    echo "Examples:"
    echo "  ./datamosh.sh video1.mp4 video2.mp4"
    echo "  ./datamosh.sh --profile extreme video1.mp4 video2.mp4 custom.mp4"
    echo "  ./datamosh.sh --gif 3 15 video1.mp4 video2.mp4"
    exit 0
}

configure_intensity() {
    log_info "Configuring intensity level $INTENSITY"
    case $INTENSITY in
        1) Q_VAL=5; DAMAGE_OFFSET_PCT=0.03; DAMAGE_SIZE=50; DAMAGE_COUNT=1; RESOLUTION="640:480";;
        2) Q_VAL=4; DAMAGE_OFFSET_PCT=0.03; DAMAGE_SIZE=100; DAMAGE_COUNT=2; RESOLUTION="640:480";;
        3) Q_VAL=3; DAMAGE_OFFSET_PCT=0.025; DAMAGE_SIZE=150; DAMAGE_COUNT=3; RESOLUTION="720:480";;
        4) Q_VAL=2; DAMAGE_OFFSET_PCT=0.02; DAMAGE_SIZE=200; DAMAGE_COUNT=4; RESOLUTION="720:480";;
        5) Q_VAL=1; DAMAGE_OFFSET_PCT=0.015; DAMAGE_SIZE=250; DAMAGE_COUNT=5; RESOLUTION="854:480";;
    esac
    log_debug "Set Q_VAL=$Q_VAL, DAMAGE_SIZE=$DAMAGE_SIZE, DAMAGE_COUNT=$DAMAGE_COUNT"
}

process_video_pair() {
    input1="$1"
    input2="$2"
    output="$3"
    
    log_info "Processing: $input1 + $input2 -> $output"
    
    # Convert to AVI with Xvid codec - with progress feedback
    log_info "Converting video 1 to AVI format..."
    ffmpeg -nostdin -y -i "$input1" -vf "scale=$RESOLUTION" -c:v libxvid -q:v $Q_VAL -g 300 -an "$WORKING_DIR/video1.avi" > /dev/null 2>> "$LOG_FILE"
    echo ""  # Ensure new line after ffmpeg
    
    log_info "Converting video 2 to AVI format..."
    ffmpeg -nostdin -y -i "$input2" -vf "scale=$RESOLUTION" -c:v libxvid -q:v $Q_VAL -g 300 -an "$WORKING_DIR/video2.avi" > /dev/null 2>> "$LOG_FILE"
    echo ""  # Ensure new line after ffmpeg
    
    # Get file sizes
    SIZE1=$(stat -c%s "$WORKING_DIR/video1.avi")
    SIZE2=$(stat -c%s "$WORKING_DIR/video2.avi")
    
    log_info "Input video sizes: $SIZE1 bytes, $SIZE2 bytes"
    
    # Calculate extraction points
    EXTRACT_SIZE=$(echo "$SIZE1 * 0.75" | bc | cut -d'.' -f1)
    SIZE2_SKIP=$(echo "$SIZE2 * 0.04" | bc | cut -d'.' -f1)
    
    log_info "Extracting $EXTRACT_SIZE bytes from first video..."
    # Use larger block size and redirect stderr to both log and null to prevent interactive prompts
    dd if="$WORKING_DIR/video1.avi" of="$WORKING_DIR/video1_part.bin" bs=1M status=none count=$((EXTRACT_SIZE/1024/1024+1)) 2>> "$LOG_FILE"
    
    log_info "Extracting bytes from second video (skipping first $SIZE2_SKIP bytes)..."
    dd if="$WORKING_DIR/video2.avi" of="$WORKING_DIR/video2_part.bin" bs=1M status=none skip=$((SIZE2_SKIP/1024/1024+1)) 2>> "$LOG_FILE"
    
    log_info "Combining video segments..."
    cat "$WORKING_DIR/video1_part.bin" "$WORKING_DIR/video2_part.bin" > "$WORKING_DIR/datamosh.avi"
    
    log_info "Applying datamosh effects with $DAMAGE_COUNT damage points..."
    
    for i in $(seq 1 $DAMAGE_COUNT); do
        # Calculate different damage points for each iteration
        OFFSET_MULTIPLIER=$(echo "scale=3; $i / $DAMAGE_COUNT" | bc)
        DAMAGE_POINT=$(echo "$EXTRACT_SIZE + ($SIZE2 * $DAMAGE_OFFSET_PCT * $OFFSET_MULTIPLIER)" | bc | cut -d'.' -f1)
        
        log_info "Applying damage point $i at position $DAMAGE_POINT (removing $DAMAGE_SIZE bytes)..."
        
        dd if="$WORKING_DIR/datamosh.avi" of="$WORKING_DIR/before.bin" bs=1M status=none count=$((DAMAGE_POINT/1024/1024+1)) 2>> "$LOG_FILE"
        dd if="$WORKING_DIR/datamosh.avi" of="$WORKING_DIR/after.bin" bs=1M status=none skip=$(((DAMAGE_POINT+DAMAGE_SIZE)/1024/1024+1)) 2>> "$LOG_FILE"
        cat "$WORKING_DIR/before.bin" "$WORKING_DIR/after.bin" > "$WORKING_DIR/temp.avi"
        mv "$WORKING_DIR/temp.avi" "$WORKING_DIR/datamosh.avi"
    done
    
    log_info "Encoding final output..."
    ffmpeg -nostdin -y -i "$WORKING_DIR/datamosh.avi" -c:v libx264 -pix_fmt yuv420p -crf 18 -preset fast "$output" > /dev/null 2>> "$LOG_FILE"
    echo ""  # Ensure new line after ffmpeg
    
    # Check result and create GIF if requested
    if [ -f "$output" ] && [ $(stat -c%s "$output") -gt 0 ]; then
        log_success "Output saved: $output"
        if [ "$GIF_OUTPUT" = true ]; then
            create_gif "$output"
        fi
    else
        log_error "Encoding failed"
        return 1
    fi
    
    return 0
}

create_gif() {
    input_file="$1"
    output_file="${input_file/.mp4/.gif}"
    log_info "Creating GIF ($GIF_DURATION s at $GIF_FPS fps)"
    
    # Create a palette for better quality
    ffmpeg -i "$input_file" -vf "fps=$GIF_FPS,scale=480:-1:flags=lanczos,palettegen" "$WORKING_DIR/palette.png" 2>> "$LOG_FILE"
    
    # Create the GIF using the palette
    ffmpeg -i "$input_file" -i "$WORKING_DIR/palette.png" -ss 0 -t "$GIF_DURATION" \
        -filter_complex "fps=$GIF_FPS,scale=480:-1:flags=lanczos[x];[x][1:v]paletteuse" "$output_file" 2>> "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        log_success "GIF created: $output_file"
    else
        log_error "GIF creation failed"
        return 1
    fi
    
    return 0
}

main() {
    init_environment "$@"
    
    # Default values
    INTENSITY=3
    RESOLUTION="720:480"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h) 
                show_help
                ;;
            --debug|-d) 
                DEBUG_MODE=true
                shift
                ;;
            --check-deps) 
                check_dependencies
                exit 0
                ;;
            --profile|-e) 
                if [ -n "$2" ]; then
                    apply_profile "$2"
                    shift 2
                else
                    log_error "Missing profile name"
                    exit 1
                fi
                ;;
            --gif|-g) 
                GIF_OUTPUT=true
                shift
                
                # Optional duration parameter
                if [[ "$1" =~ ^[0-9]+$ ]]; then
                    GIF_DURATION="$1"
                    shift
                    
                    # Optional FPS parameter
                    if [[ "$1" =~ ^[0-9]+$ ]]; then
                        GIF_FPS="$1"
                        shift
                    fi
                fi
                ;;
            *)
                # Process input/output parameters
                if [ -z "$INPUT_FILE_1" ]; then
                    INPUT_FILE_1="$1"
                elif [ -z "$INPUT_FILE_2" ]; then
                    INPUT_FILE_2="$1"
                elif [[ "$1" =~ ^[1-5]$ ]]; then
                    # Intensity provided as third argument
                    INTENSITY="$1"
                else
                    # Custom output name
                    OUTPUT_FILE="$1"
                fi
                shift
                ;;
        esac
    done
    
    # Check for required input files
    if [ -z "$INPUT_FILE_1" ] || [ -z "$INPUT_FILE_2" ]; then
        log_error "Missing input files"
        show_help
    fi
    
    # Generate timestamp for output filename
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    
    # Set default output filename if not provided
    if [ -z "$OUTPUT_FILE" ]; then
        OUTPUT_FILE="datamoshed_${TIMESTAMP}.mp4"
    else
        # Ensure output file has timestamp
        output_dir=$(dirname "$OUTPUT_FILE")
        output_base=$(basename "$OUTPUT_FILE" .mp4)
        OUTPUT_FILE="${output_dir}/${output_base}_${TIMESTAMP}.mp4"
    fi
    
    # Check dependencies
    check_dependencies
    
    # Validate input parameters
    validate_inputs
    
    # If no profile was applied, configure based on intensity
    if [ -z "$ACTIVE_PROFILE" ]; then
        configure_intensity
    fi
    
    # Process the videos
    process_video_pair "$INPUT_FILE_1" "$INPUT_FILE_2" "$OUTPUT_FILE"
    
    log_info "Done! Output: $OUTPUT_FILE"
    
    if [ -n "$ACTIVE_PROFILE" ]; then
        log_info "Used profile: $ACTIVE_PROFILE"
    else 
        log_info "Used intensity: $INTENSITY"
    fi
    
    log_info "Intermediate files preserved in $WORKING_DIR"
}

main "$@"