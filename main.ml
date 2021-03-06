open Syntax

let position_to_string pos = 
  "file:" ^ pos.Lexing.pos_fname ^ ", line:" ^ string_of_int(pos.Lexing.pos_lnum) ^ ", col:" ^ string_of_int(pos.Lexing.pos_cnum)

(* 環境。名前と term を紐付ける *)
let empty_context : (string * term) list = []


exception LambdaError of string

let rec term_to_string term =
  match term with
  |TmVar(_, v) -> v
  |TmAbs(_, v, t) -> "(λ" ^ v ^ ". " ^ term_to_string t ^ ")"
  |TmApp(_, t1, t2) -> "(" ^ (term_to_string t1) ^ " " ^ (term_to_string t2) ^ ")"

(* 関数の適用 *)
let rec apply ctx t1 t2 =
  match t1 with
  |TmAbs(_, v, t) ->
      let ctx' = (v, t2)::ctx in
      eval ctx' t
  |_ ->
      (* t1 がλ抽象出ないときはそっともとに戻しておく *)
      (ctx, TmApp(Lexing.dummy_pos, t1, t2))

and eval ctx term =
  match term with
  |TmVar(_, v) ->
      begin
        try
          let v' = List.assoc v ctx in
          (ctx, v')
        (* 見つからなかったときに id 関数のように振る舞うことで未定義の変数を使えて便利 *)
        with Not_found -> (ctx, term)
      end
  |TmApp(_, t1, t2) ->
      let _, t2' = eval ctx t2 in
      let ctx', t1' = eval ctx t1 in
      apply ctx' t1' t2'
  |_ -> (ctx, term)

let rec context_of_string ctx =
  match ctx with
  |(n, t)::xs -> n ^ "->" ^ (term_to_string t) ^ ", " ^ (context_of_string xs)
  |[] -> ""

let () =
  let ctx = ref [] in
  while true do
    try
      print_string ">";
      flush stdout;
      let stmt = Parser.parse Lexer.main (Lexing.from_channel stdin) in
      match stmt with
      |Term(t) ->
          begin
            print_endline ("->" ^ term_to_string t);
            let _, r = eval !ctx t in 
            print_endline ("->" ^ term_to_string r);
            print_endline ("["^context_of_string !ctx^"]")
          end
      |Assign(_, v, t) ->
          begin
            print_endline ("->" ^ term_to_string t);
            let ctx', r = eval !ctx t in 
            ctx := (v, r)::ctx';
            print_endline ("->" ^ term_to_string r);
            print_endline ("["^context_of_string !ctx^"]")
          end
    with Parser.Error -> print_endline "[error] syntax error."
  done

