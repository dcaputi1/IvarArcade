To test whether disabling HDMI audio alone fixes ES, temporarily move that ALSA override out of the way, then reboot:

sudo mv /etc/asound.conf.disabled /etc/asound.conf
sudo reboot

The head output should identify the generated config, including the # /etc/asound.conf header. After reboot, test sound in ES. HDMI audio stays disabled; the reboot applies that boot-config change.

To restore the ALSA config afterward:

sudo mv /etc/asound.conf.disabled /etc/asound.conf
sudo reboot

This preserves the current ALSA config for restoring the test setup. The script doesn’t save any older /etc/asound.conf it may have replaced, so this won’t recover a pre-script config.