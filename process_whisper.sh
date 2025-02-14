#!/bin/bash

# Check if the required arguments were provided
if [ $# -lt 7 ]; then
    echo "Usage: $0 <MODELS_DIR> <AUDIOS_DIR> <AUDIO_DIR> <AUDIO_FILE> <MODEL_FILE> <OFFSET_DURATION_MINUTES> <AUDIO_DURATION_MINUTES>"
    exit 1
fi

# Assign arguments to variables
MODELS_DIR="$1"
AUDIOS_DIR="$2"
AUDIO_DIR="$3"
AUDIO_FILE="$4"
MODEL_FILE="$5"
OFFSET_DURATION_MINUTES="$6"
AUDIO_DURATION_MINUTES="$7"

# Convert minutes to milliseconds
OFFSET_STEP=$((OFFSET_DURATION_MINUTES * 60 * 1000))
DURATION_LIMIT=$OFFSET_STEP

# General parameters
LANGUAGE="English"
THREADS=6
MAX_CONTEXT=64
MAX_LENGTH=128

# Iteration values
OFFSET=0
ITERATION=0

# Calculate total duration in ms
TOTAL_DURATION_MS=$((AUDIO_DURATION_MINUTES * 60 * 1000))

while true; do
    ITERATION=$((ITERATION + 1))
    
    # Construct the internal command
    DOCKER_COMMAND="./main -m $MODEL_FILE -f /audios/$AUDIO_DIR/$AUDIO_FILE -l $LANGUAGE -t $THREADS -otxt -di"
    
    # Add offset if greater than 0
    if [ $OFFSET -gt 0 ]; then
        DOCKER_COMMAND="$DOCKER_COMMAND -ot $OFFSET"
    fi
    
    # Add duration limit if it's not the last iteration
    if [ $((OFFSET + DURATION_LIMIT)) -lt $TOTAL_DURATION_MS ]; then
        DOCKER_COMMAND="$DOCKER_COMMAND -d $DURATION_LIMIT"
    fi
    
    # Construct the complete Docker command
    COMMAND="docker run -it --rm -v $MODELS_DIR:/models -v $AUDIOS_DIR:/audios ghcr.io/ggerganov/whisper.cpp:main $DOCKER_COMMAND"
    
    echo "Executing iteration $ITERATION with command:"
    echo "$COMMAND"
    
    # Execute the command
    eval $COMMAND
    
    # Rename the output file to include the iteration number
    OUTPUT_FILE="${AUDIOS_DIR}/${AUDIO_DIR}/${AUDIO_FILE}.txt"
    RENAMED_OUTPUT="${AUDIOS_DIR}/${AUDIO_DIR}/${AUDIO_FILE}-part${ITERATION}.txt"
    if [ -f "$OUTPUT_FILE" ]; then
        mv "$OUTPUT_FILE" "$RENAMED_OUTPUT"
        echo "Output file renamed to: $RENAMED_OUTPUT"
    else
        echo "Error: Output file not found!"
        break
    fi
    
    # Increment the offset
    OFFSET=$((OFFSET + OFFSET_STEP))
    
    # Stop the loop if the offset exceeds the total audio duration
    if [ $OFFSET -ge $TOTAL_DURATION_MS ]; then
        echo "Processing complete."
        break
    fi
done
