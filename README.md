# gropdf-otf

This repository creates an ubuntu VM box for creating Japanese PDFs
with groff (gropdf).

    git clone https://github.com/obuk/gropdf-otf.git
    cd gropdf-otf
    vagrant up
    vagrant ssh
    cd /vagrant
    make roff.pdf

To use Japanese with groff, users need to install Japanese fonts, but
the procedure is not easy.  That's why this repository contains the
tools and installation instructions (Makefiles) required to use
Japanese OTF as is.

otftodit (replacing afmtodit) in this repository uses the tx
(afdko) command to get AFM from OTF and output a groff font, including
the opentype feature settings.

In groff, four styles (R, B, I, BI) consisting of combinations of
weights and shapes are usually associated with each family, but here,
vertical writing styles (V, BV, IV, BIV) are also associated.
