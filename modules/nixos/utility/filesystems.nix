{ ... }:
{
  fileSystems."/mnt/games" = {
    device = "/dev/disk/by-uuid/12ef98a6-ad00-4a03-b80b-9b526717e67a";
    fsType = "ext4";
    options = [
      "rw"
      "nofail"
    ];
  };
}
