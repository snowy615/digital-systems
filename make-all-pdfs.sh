#!/bin/bash

# Initialize default states
RUN_SLIDES=true
RUN_LABS=true

# Parse flags
for arg in "$@"; do
  case $arg in
    --labs)
      RUN_SLIDES=false
      ;;
    --slides)
      RUN_LABS=false
      ;;
  esac
done

# run if no flags, but do not run if --labs is present
if [ "$RUN_SLIDES" = true ]; then
    echo "Compiling slides..."
    cd materials-src/digital-systems-slides
    ./compile-slides.sh lecture*.typ
    cd ../..
fi

# run if no flags, but do not run if --slides is present
if [ "$RUN_LABS" = true ]; then
    echo "Compiling labs..."
    cd materials-src/digital-systems-labs
    typst compile lab0.typ
    mv lab0.pdf ../../labs/
    typst compile lab1.typ
    mv lab1.pdf ../../labs/
    typst compile lab2.typ --root ..
    mv lab2.pdf ../../labs/
    typst compile lab3.typ
    mv lab3.pdf ../../labs/
    cd ../..
fi

# mv materials-src/digital-systems-slides/pdf/*_handout.pdf ./lecture-slides
# mv materials-src/digital-systems-labs/labs.pdf .
