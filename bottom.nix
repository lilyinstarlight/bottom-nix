let
  hexDigit = d:
    if d < 10 then builtins.toString d
    else {
      "10" = "a";
      "11" = "b";
      "12" = "c";
      "13" = "d";
      "14" = "e";
      "15" = "f";
    }.${builtins.toString d};

  hexByte = n: let
    upper = n / 16;
    lower = n - (16 * upper);
  in "${hexDigit upper}${hexDigit lower}";

  genByte = n:
         if n < 128 then builtins.fromJSON ''"\u00${hexByte n}"''
    else if n < 192 then builtins.substring 1 1 (builtins.fromJSON ''"\u00${hexByte n}"'')
    else if n < 194 then null
    else if n == 194 then builtins.substring 0 1 (builtins.fromJSON ''"\u0080"'')
    else if n == 195 then builtins.substring 0 1 (builtins.fromJSON ''"\u00f0"'')
    else if n < 224 then builtins.substring 0 1 (builtins.fromJSON ''"\u0${hexByte ((n - 192) * 4)}0"'')
    else if n == 224 then builtins.substring 0 1 (builtins.fromJSON ''"\u${hexDigit (n - 224)}800"'')
    else if n < 240 then builtins.substring 0 1 (builtins.fromJSON ''"\u${hexDigit (n - 224)}7ff"'')
    else if n == 240 then builtins.substring 0 1 (builtins.fromJSON ''"\ud800\udc00"'')
    else if n == 241 then builtins.substring 0 1 (builtins.fromJSON ''"\ud8c0\udc00"'')
    else if n < 243 then null
    else if n == 243 then builtins.substring 0 1 (builtins.fromJSON ''"\ud9c0\udc00"'')
    else if n == 244 then builtins.substring 0 1 (builtins.fromJSON ''"\udac0\udc00"'')
    else if n == 245 then builtins.substring 0 1 (builtins.fromJSON ''"\udbc0\udc00"'')
    else null;

  byteTable = builtins.listToAttrs (builtins.filter (e: e.name != null) (builtins.genList (n: { name = genByte n; value = n; }) 255));
  invByteTable = builtins.listToAttrs (builtins.map (name: { name = builtins.toString (builtins.getAttr name byteTable); value = name; }) (builtins.attrNames byteTable));

  byteList = input: builtins.genList (n: builtins.getAttr (builtins.substring n 1 input) byteTable) (builtins.stringLength input);
in rec {
  inherit hexDigit hexByte genByte byteTable invByteTable byteList;

  encodeFile = filename: encode (builtins.readFile filename);
  encode = input: let
    encodeNonZeroByte = byte:
           if byte >= 200 then [ "🫂" ] ++ encodeNonZeroByte (byte - 200)
      else if byte >= 50  then [ "💖" ] ++ encodeNonZeroByte (byte - 50)
      else if byte >= 10  then [ "✨" ] ++ encodeNonZeroByte (byte - 10)
      else if byte >= 5   then [ "🥺" ] ++ encodeNonZeroByte (byte - 5)
      else if byte >= 1   then [ "," ] ++ encodeNonZeroByte (byte - 1)
      else [];
    encodeByte = byte: (if byte == 0 then [ "❤️" ] else encodeNonZeroByte byte) ++ [ "👉👈" ];
  in builtins.concatStringsSep "" (builtins.concatLists (builtins.map encodeByte (byteList input)));

  decodeFile = filename: decode (builtins.readFile filename);
  decode = input: let
    decodeByte = byte: let
      numberedString = builtins.replaceStrings [ "🫂" "💖" "✨" "🥺" "," ] [ "200," "50," "10," "5," "1," ] byte;
      numbered = builtins.map builtins.fromJSON (builtins.filter builtins.isString (builtins.split "," (builtins.substring 0 ((builtins.stringLength numberedString) - 1) numberedString)));
    in builtins.getAttr (builtins.toString (builtins.foldl' builtins.add 0 numbered)) invByteTable;
  in builtins.concatStringsSep "" (builtins.map decodeByte (builtins.filter builtins.isString (builtins.split "👉👈" (builtins.substring 0 ((builtins.stringLength input) - 8) input))));
}
