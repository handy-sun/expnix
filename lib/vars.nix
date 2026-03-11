rec {
  user = "qi";
  homeDir = if "${user}" == "root" then "/root" else "/home/${user}";
}