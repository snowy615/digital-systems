#!/bin/bash
set -e

for file_name in "$@"; do
    file_name_noext="${file_name%.*}"
    handout_name="../../lecture-slides/${file_name_noext}_handout.pdf"
    slides_name="./pdf/${file_name_noext}_slides.pdf"

    
    echo "Handout: ${file_name}"
    sed -i '' 's/\/\/ #enable-handout-mode/#enable-handout-mode/g' ${file_name}
    typst compile ${file_name}
    mv ${file_name_noext}.pdf ${handout_name}

    echo "Slides: ${file_name}"
    sed -i '' 's/#enable-handout-mode/\/\/ #enable-handout-mode/g' ${file_name}
    typst compile ${file_name}
    mv ${file_name_noext}.pdf ${slides_name}

    # if ! grep -q 'handout]{beamer}' ${file_name}; then
    #     sed -i '' 's/]{beamer}/,handout]{beamer}/g' ${file_name}
    # fi

    # echo "pdflatex"
    # pdflatex ${file_name} > /dev/null
    # echo "bibtex"
    # bibtex ${file_name_noext} > /dev/null
    # echo "pdflatex"
    # pdflatex ${file_name} > /dev/null
    # mv ${file_name_noext}.pdf ${handout_name}

    # 
    # if grep -q 'handout]{beamer}' ${file_name}; then
    #     sed -i '' 's/,handout]{beamer}/]{beamer}/g' ${file_name}
    # fi
    # pdflatex ${file_name} > /dev/null
    # pdflatex ${file_name} > /dev/null  # Run again to get references right
    # 

    echo ""
done
