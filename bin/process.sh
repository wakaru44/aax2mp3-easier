#!/usr/bin/env bash
#
#
# Script to process audio files.
# It will list what is pending to be processed in the 'source_books' folder.
# then for each book it will convert, then move to 'converted_books' folder.

#------------------
# Enable soft strict mode
set -euo pipefail
IFS=$'\n\t'

#------------------

function convert_book() {
    book=$1
    echo "Converting book: ${book}"
    # Convert to flac using the previously downloaded AAXtoMP2 tool and the activation bytes
    # check Makefile for more details.

    # FLAC mode
    #./AAXtoMP3-master/AAXtoMP3 --flac \
    # MP3 mode
    ./AAXtoMP3-master/AAXtoMP3 \
        -A $(cat .secrets/activation_bytes) \
        --target_dir ./output_books \
        ${book}
}

function move_book() {
    book=$1
    echo "Moving book: ${book}"
    mv $book ./converted_books
}

function process_book() {
    book=$1
    convert_book ${book}
    move_book ${book}
}

function process_books() {
    # Get the books to be processed.
    books_n=$(find ./source_books -name "*.aax" | wc -l)
    echo "Found books: ${books_n}"
    while IFS= read -r -d $'\0' book; do
        process_book ${book}
    done < <(find ./source_books -type f -print0)
}

function main() {
    process_books
}
main
