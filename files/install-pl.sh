#!/bin/sh
SOURCE=$1
NAME="${2-${SOURCE##*/}}"
HOME=$(getent passwd ${USER:-vagrant} | cut -d: -f6)
export PLENV_ROOT="$HOME/.plenv"
set -- `bash -lc 'plenv version'`
VERSION=$1
(
    echo "#!$PLENV_ROOT/versions/$VERSION/bin/perl$VERSION"
    sed -E "1{/^#!/d}" $SOURCE
) > "$PLENV_ROOT/versions/$VERSION/bin/$NAME"
cat <<EOF >"$PLENV_ROOT/shims/$NAME"
#!/bin/sh
PLENV_ROOT='$HOME/.plenv' exec '$PLENV_ROOT/libexec/plenv' exec "\${0##*/}" "\$@"
EOF
chmod +x "$PLENV_ROOT/versions/$VERSION/bin/$NAME"
chmod +x "$PLENV_ROOT/shims/$NAME"
