{
  networking.interfaces.eth0.ipv4.addresses = [
    {
      address = "<ipv4-address>";
      prefixLength = 23;
    }
  ];

  networking.defaultGateway = {
    address = "<gateway-address>";
    interface = "eth0";
  };
}
