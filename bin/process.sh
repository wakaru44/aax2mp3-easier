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

function convert_audidible() {
    #
    # Audible integration
    # TODO: por ahora no me va la integracion, no descarga metadatos.
    #
    # Some information are not present in the AAX file. For example the 
    # chapters's title, additional chapters division (Opening and End credits,
    # Copyright and more). Those information are avaiable via a non-public
    # audible API. This repo provides a python API wrapper, and the audible-cli
    # packege makes easy to get more info. In particular the flags
    # --cover --cover-size 1215 --chapter
    # downloads a better-quality cover (.jpg) and detailed chapter infos (.json).
    # More info are avaiable on the package page.

    # Some books might not be avaiable in the old aax format, but only in the
    # newer aaxc format. In that case, you can use audible-cli to download them.
    # For example, to download all the books in your library in the newer aaxc 
    # format, as well as chapters's title and an HQ cover:
    # audible download --all --aaxc --cover --cover-size 1215 --chapter.

    # To make AAXtoMP3 use the additional data, specify the
    # --use-audible-cli-data flag: it expects the cover and the chapter files
    # (and the voucher, if converting an aaxc file) to be in the same location
    # of the AAX file. The naming of these files must be the one set by
    # audible-cli. When converting aaxc files, the variable is automatically
    # set, so be sure to follow the instructions in this paragraph.

    book=$1
    echo "Converting book: ${book}"
    # Convert to flac using the previously downloaded AAXtoMP2 tool and 
    # use extra data from audible-cli

    # get extra details from audible-cli
    audible download --all --aaxc --cover --cover-size 1215 --chapter ${book}
    # convert to flac
    (
    ./AAXtoMP3-master/AAXtoMP3 --flac --chaptered --loglevel 2 \
        -A $(cat .secrets/activation_bytes) \
        --target_dir ./output_books \
        --use-audible-cli-data \
        ${book}
    echo "conversion result: $?"
    ) || echo "conversion did not finish correctly for book: ${book}"

}

function convert_book() {
    book=$1
    echo "Converting book: ${book}"
    # Convert to flac using the previously downloaded AAXtoMP2 tool and the activation bytes
    # check Makefile for more details.

    # FLAC mode
    # Log level: 1 info; 2 detailed info; 3 debug;
    #./AAXtoMP3-master/AAXtoMP3 --flac --chaptered --loglevel 2 \
    # MP3 mode
    # NOTE: Even when everything seems alright, the process ends in 1, interupting the script.
    (
        ./AAXtoMP3-master/AAXtoMP3 \
            -A $(cat .secrets/activation_bytes) \
            --target_dir ./output_books \
            ${book}
        echo "conversion result: $?"
    ) || echo "conversion did not finish correctly for book: ${book}"
    #echo "NO OP on book: ${book}"
}

function move_book() {
    book=$1
    echo "Moving book: ${book}"
    mv $book ./converted_books
}

function process_book() {
    book=$1
    convert_book ${book}
    echo "done converting book: ${book}"
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
