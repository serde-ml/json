open Serde

let ( let* ) = Result.bind

type local = bool [@@deriving serializer]

module Other = struct
  type other = int [@@deriving serializer]
end

type t =
  | Hello
  | Tuple1 of string
  | Tuple2 of string * bool
  | Record3 of { name : string; favorite_number : int; location : string }
[@@deriving serializer]

module Serde_deserialize_t = struct
  let name = "t"
  let variants = [ "Hello"; "Tuple1"; "Salute" ]

  type fields = Field_Hello | Field_Tuple1 | Field_Tuple2 | Field_Record3

  module Variant_visitor : Serde.De.Visitor.Intf with type value = fields =
  Serde.De.Visitor.Make (struct
    include Serde.De.Visitor.Unimplemented

    type value = fields
    type tag = unit

    let visit_int idx =
      match idx with
      | 0 -> Ok Field_Hello
      | 1 -> Ok Field_Tuple1
      | 2 -> Ok Field_Tuple2
      | _ -> Serde.De.Error.invalid_variant_index ~idx

    let visit_string str =
      match str with
      | "Hello" -> Ok Field_Hello
      | "Tuple1" -> Ok Field_Tuple1
      | "Tuple2" -> Ok Field_Tuple2
      | "Record3" -> Ok Field_Record3
      | _ -> Serde.De.Error.unknown_variant str

    let _ = visit_string
  end)

  module Field_Tuple1_visitor : Serde.De.Visitor.Intf with type value = t =
  Serde.De.Visitor.Make (struct
    open Serde.De
    include Visitor.Unimplemented

    type value = t
    type tag = unit

    let visit_seq :
        (module Visitor.Intf with type value = value) ->
        (module Deserializer) ->
        (value, 'error) Sequence_access.t ->
        (value, 'error Error.de_error) result =
     fun (module Self) (module De) seq_access ->
      let open Serde.De.Impls in
      let* f0 =
        let deser_element () =
          Serde.De.deserialize_string (module De) (module String_visitor)
        in
        let* r = Sequence_access.next_element seq_access ~deser_element in
        match r with
        | None -> Error.message (Printf.sprintf "t.Tuple2 needs 2 argument")
        | Some f0 -> Ok f0
      in
      Ok (Tuple1 f0)
  end)

  module Field_Tuple2_visitor : Serde.De.Visitor.Intf with type value = t =
  Serde.De.Visitor.Make (struct
    open Serde.De
    include Visitor.Unimplemented

    type value = t
    type tag = unit

    let visit_seq :
        (module Visitor.Intf with type value = value) ->
        (module Deserializer) ->
        (value, 'error) Sequence_access.t ->
        (value, 'error Error.de_error) result =
     fun (module Self) (module De) seq_access ->
      let open Serde.De.Impls in
      let* f0 =
        let deser_element () =
          Serde.De.deserialize_string (module De) (module String_visitor)
        in
        let* r = Sequence_access.next_element seq_access ~deser_element in
        match r with
        | None -> Error.message (Printf.sprintf "t.Tuple2 needs 2 argument")
        | Some f0 -> Ok f0
      in

      let* f1 =
        let deser_element () =
          Serde.De.deserialize_bool (module De) (module Bool_visitor)
        in
        let* r = Sequence_access.next_element seq_access ~deser_element in
        match r with
        | None -> Error.message (Printf.sprintf "t.Tuple2 needs 2 argument")
        | Some f1 -> Ok f1
      in

      Ok (Tuple2 (f0, f1))
  end)

  module Field_Record3_visitor : Serde.De.Visitor.Intf with type value = t =
  Serde.De.Visitor.Make (struct
    open Serde.De
    include Visitor.Unimplemented

    type value = t
    type tag = unit

    let visit_seq :
        (module Visitor.Intf with type value = value) ->
        (module Deserializer) ->
        (value, 'error) Sequence_access.t ->
        (value, 'error Error.de_error) result =
     fun (module Self) (module De) seq_access ->
      let open Serde.De.Impls in
      let* f0 =
        let deser_element () =
          Serde.De.deserialize_string (module De) (module String_visitor)
        in
        let* r = Sequence_access.next_element seq_access ~deser_element in
        match r with
        | None -> Error.message (Printf.sprintf "t.Record3 needs 3 argument")
        | Some f0 -> Ok f0
      in

      let* f1 =
        let deser_element () =
          Serde.De.deserialize_int (module De) (module Int_visitor)
        in
        let* r = Sequence_access.next_element seq_access ~deser_element in
        match r with
        | None -> Error.message (Printf.sprintf "t.Record3 needs 3 argument")
        | Some f1 -> Ok f1
      in

      let* f2 =
        let deser_element () =
          Serde.De.deserialize_string (module De) (module String_visitor)
        in
        let* r = Sequence_access.next_element seq_access ~deser_element in
        match r with
        | None -> Error.message (Printf.sprintf "t.Record3 needs 3 argument")
        | Some f2 -> Ok f2
      in

      Ok (Record3 { name = f0; favorite_number = f1; location = f2 })
  end)

  module Visitor :
    Serde.De.Visitor.Intf with type value = t and type tag = fields =
  Serde.De.Visitor.Make (struct
    open Serde.De
    include Visitor.Unimplemented

    type value = t
    type tag = fields

    let visit_unit () = Ok ()

    let visit_variant va =
      let* tag = Variant_access.tag va in
      match tag with
      | Field_Hello ->
          let* () = Variant_access.unit_variant va in
          Ok Hello
      | Field_Tuple1 ->
          Variant_access.tuple_variant va (module Field_Tuple1_visitor)
      | Field_Tuple2 ->
          Variant_access.tuple_variant va (module Field_Tuple2_visitor)
      | Field_Record3 ->
          Variant_access.record_variant va (module Field_Record3_visitor)
  end)

  let deserialize_t (module De : Serde.De.Deserializer) =
    Serde.De.deserialize_variant ~name ~variants
      (module De)
      (module Visitor)
      (module Variant_visitor)
end

include Serde_deserialize_t

let round_trip str =
  let* t =
    str
    |> Serde_sexpr.of_string deserialize_t
    |> Result.map_error (fun e -> `De e)
  in
  let* sexpr =
    t
    |> Serde_sexpr.to_string_pretty serialize_t
    |> Result.map_error (fun e -> `Ser_sexpr e)
  in
  let* json =
    t
    |> Serde_json.to_string_pretty serialize_t
    |> Result.map_error (fun e -> `Ser_json e)
  in
  let* xml =
    t
    |> Serde_xml.to_string_pretty serialize_t
    |> Result.map_error (fun e -> `Ser_xml e)
  in
  Ok (sexpr, json, xml)

let print str =
  match round_trip str with
  | Ok (sexpr, json, xml) ->
      Printf.printf "from: %s\nto (sexpr): %s\nto (json): %s\nto (xml): %s\n\n"
        str sexpr json xml;
      String.equal sexpr str
  | Error (`De (`Unimplemented msg)) ->
      print_string ("unimplemented: " ^ msg);
      false
  | Error (`De (`Invalid_variant_index _)) ->
      print_string "invalid_va_idx";
      false
  | Error (`De (`Unknown_variant s)) ->
      print_string ("Unknown_variant: " ^ s);
      false
  | Error (`De (`Duplicate_field _)) ->
      print_string "Duplicate_field";
      false
  | Error (`De (`Missing_field _)) ->
      print_string "Missing_field";
      false
  | Error (`De (`Message msg)) ->
      print_string ("msg: " ^ msg);
      false
  | Error (`Ser _) ->
      print_string "error serializing";
      false
  | _ ->
      print_string "other";
      false

let%test "Deserialize unit variant Hello" = print ":Hello"

(* TODO(@ostera): reenable this after we figure out how to make Sexplib print out string correctly
   let%test "Deserialize tuple variant Tuple1(string)" =
     print "(:Tuple1 (\"asdf\"))"
*)

let%test "Deserialize tuple variant Tuple1(string) with spaces" =
  print "(:Tuple1 (\"a string with spaces\"))"

let%test "Deserialize tuple variant Tuple2(string, bool) with spaces" =
  print "(:Tuple2 (\"a string with spaces\" true))"

let%test "Deserialize tuple variant Tuple2(string, bool) with spaces" =
  print "(:Tuple2 (\"a string with spaces\" false))"

let%test "Deserialize tuple variant Tuple2(string, bool) with spaces" =
  print "(:Record3 (\"Benjamin Sisko\" 9 \"Deep Space 9\"))"
