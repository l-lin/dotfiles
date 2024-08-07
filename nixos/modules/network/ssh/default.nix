#
# SSH related stuff.
#

{ userSettings, ... }: {
  services.openssh = {
    enable = true;
    settings = {
      AllowUsers = [ userSettings.username ];
      # Allow ssh using passphrase, for easier connection to VM.
      # Enable the following if you installed NixOS in a VM and you want to ssh in.
      #PasswordAuthentication = true;
      #PermitRootLogin = "yes";
    };
  };

  # Start the OpenSSH agent when you log in.
  # The OpenSSH agent remembers private keys for you so that you don’t have to type in passphrases
  # every time you make an SSH connection.
  # Use ssh-add to add a key to the agent.
  programs.ssh.startAgent = true;
}
