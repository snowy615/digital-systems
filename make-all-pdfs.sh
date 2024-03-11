cd src/digital-systems-slides
./compile-slides.sh lecture*.typ
cd ../digital-systems-labs
typst compile labs.typ
cd ../..

mv src/digital-systems-slides/pdf/*_handout.pdf ./lecture-slides
mv src/digital-systems-labs/labs.pdf .
