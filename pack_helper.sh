#!/bin/sh
zip magisk-ddns-go.zip ./ -r -x LICENSE -x README.MD -x '.git/*' -x magisk-ddns-go.zip -x pack_helper.sh -x '.gitignore' -x 'bin/.gitignore' -x 'config/.gitignore'
