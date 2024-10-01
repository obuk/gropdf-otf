# gropdf-otf

This repository creates an ubuntu VM box for creating Japanese PDFs
with groff (gropdf).

    git clone https://github.com/obuk/gropdf-otf.git
    cd gropdf-otf
    vagrant up
    vagrant ssh
    cd /vagrant
    make roff.pdf

When using Japanese with groff, Japanese fonts are required. In this
case, it is easier to install OTF than PFA or PFB, so I would like to
make the necessary changes so that OTF can be used.

otftodit (alternative to afmtodit) in this repository uses the tx
(afdko) command to get AFM from OTF and output a groff font, including
the opentype feature settings.

In groff, four styles (R, B, I, BI) consisting of combinations of
weight and shape are usually associated with each family, but here,
vertical writing styles (V, BV) are also associated.

This is still in the prototype stage, so there may be some defects,
but please bear with us.
