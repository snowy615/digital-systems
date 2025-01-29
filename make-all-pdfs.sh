cd materials-src/digital-systems-slides
./compile-slides.sh lecture*.typ
cd ../digital-systems-labs
typst compile labs.typ
cd ../..

mv materials-src/digital-systems-slides/pdf/*_handout.pdf ./lecture-slides
# mv materials-src/digital-systems-labs/labs.pdf .
