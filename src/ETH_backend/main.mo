import Error "mo:base/Error";
import Types "Type"; // file name inside it ""
import Array "mo:base/Array";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Nat64 "mo:base/Nat64";
import Text "mo:base/Text";
import Blob "mo:base/Blob";
import Nat "mo:base/Nat";

shared actor class ETHPrice() = this {
  let DATA_POINTS_PER_API : Nat64 = 200;
  let MAX_RESPONSE_BYTES : Nat64 = 10 * 6 * DATA_POINTS_PER_API;

  public query func transform(raw : Types.TransformArgs) : async Types.CanisterHttpResponsePayload {
    let transformed : Types.CanisterHttpResponsePayload = {
      status = raw.response.status;
      body = raw.response.body;
      headers = [
        {
          name = "Content-Security-Policy";
          value = "default-src 'self'";
        },
        { name = "Referrer-Policy"; value = "strict-origin" },
        { name = "Permissions-Policy"; value = "geolocation=(self)" },
        {
          name = "Strict-Transport-Security";
          value = "max-age=63072000";
        },
        { name = "X-Frame-Options"; value = "DENY" },
        { name = "X-Content-Type-Options"; value = "nosniff" },
      ];
    };
    transformed;
  };

  public type Result<ok, err> = {
    #Ok : ok;
    #Err : err;
  };

  public shared (msg) func fetch_ethereum_price() : async Result<Text, Text> {
    let transform_context : Types.TransformContext = {
      function = transform;
      context = Blob.fromArray([]);
    };
    let url = "https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd";


    let request : Types.CanisterHttpRequestArgs = {
      url = url;
      max_response_bytes = ?MAX_RESPONSE_BYTES;
      headers = [];
      body = null;
      method = #get;
      transform = ?transform_context;
    };
    try {
      Cycles.add(2_000_000_000);
      let ic : Types.IC = actor ("aaaaa-aa");
      let response : Types.CanisterHttpResponsePayload = await ic.http_request(request);
      switch (Text.decodeUtf8(Blob.fromArray(response.body))) {
        case null {
          #Err("Remote response had no body.");
        };
        case (?body) {
          var headers : Text = "";
          for (header in response.headers.vals()) {
            headers := headers # header.name # ": " # header.value # ";";
            Debug.print(debug_show response.status); 
            Debug.print(debug_show response.headers);
            Debug.print(debug_show header);

          };
          #Ok("; Body: " # body);

        };
      };
    } catch (err) {
      #Err(Error.message(err));
    };
  };
};
