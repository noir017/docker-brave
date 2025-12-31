export DISPLAY=:99
export XAUTHORITY=${DATA_DIR}/.Xauthority

# Use passed BRAVE_DIR if provided, otherwise use environment variable
if [ -n "$1" ]; then
    export BRAVE_DIR="$1"
fi

# Run as user user
chmod +x fix_brave_lock.sh
fix_brave_lock.sh ${BRAVE_DIR}
cd ${BRAVE_DIR}
su - user -c "brave-browser --user-data-dir=${BRAVE_DIR} --disable-accelerated-video --disable-gpu --window-size=${CUSTOM_RES_W},${CUSTOM_RES_H} --no-sandbox --test-type --dbus-stub ${EXTRA_PARAMETERS}" 2>/dev/null



