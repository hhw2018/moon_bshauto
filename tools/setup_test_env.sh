#!/usr/bin/bash

#for p in functional stress performance longevity; do
for p in functional stress; do
cd $MOON_BSHAUTO_HOME/tests/$p

for d in $(seq 1 3 10); do
    mkdir dir_$d
    cd dir_$d
    MOON_BSHAUTO_TC_DIR=$MOON_BSHAUTO_HOME/tests/$p/dir_$d
cat > config <<EOF
export config=dir_$d/config
EOF

cat > dir_$d.bshlib <<EOF
function cleanup {
    log_msg "dir_$d: onexit"
}

function cleanup1 {
    log_msg "dir_$d: onexit1"
}
EOF

((d == 1)) && log=log_fail || log=log_pass
cat > setup <<EOF
. \$MOON_BSHAUTO_TC_DIR/dir_$d.bshlib
log_assert "begin dir_$d/setup"
log_msg "dir_$d/setup"
$log "end dir_$d/setup"
EOF

cat > cleanup <<EOF
. \$MOON_BSHAUTO_TC_DIR/dir_$d.bshlib
log_assert "begin dir_$d/cleanup"
log_msg "dir_$d/cleanup"
log_pass "end dir_$d/cleanup"
EOF

cat > dir_${d}_tc3 <<EOF
. \$MOON_BSHAUTO_TC_DIR/dir_$d.bshlib
log_onexit cleanup
log_assert "begin dir_$d/dir_${d}_tc3"
log_msg "dir_$d/dir_${d}_tc3"
log_pass "end dir_$d/dir_${d}_tc3"
EOF

cat > dir_${d}_tc2 <<EOF
. \$MOON_BSHAUTO_TC_DIR/dir_$d.bshlib
log_onexit cleanup1
log_assert "begin dir_$d/dir_${d}_tc2"
log_msg "dir_$d/dir_${d}_tc2"
log_msg "\$config"
log_fail "end dir_$d/dir_${d}_tc2"
EOF

cat > dir_${d}_tc1 <<EOF
. \$MOON_BSHAUTO_TC_DIR/dir_$d.bshlib
log_onexit cleanup
log_msg "dir_$d/dir_${d}_tc1"
log_must rcmd_host localhost "egrep '^abc|def$' /tmp/file"
log_must rcml_host localhost "egrep '^abc|def$' /tmp/file"
EOF
    chmod +x *
    cd -
done
done
