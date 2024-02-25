(lang dune 3.13)
(cram enable)

(name serde_json)

(generate_opam_files true)

(source
 (github serde-ml/json))

(authors "Leandro Ostera <leandro@abstractmachines.dev>")

(maintainers "Leandro Ostera <leandro@abstractmachines.dev>")

(license "MIT")

(package
 (name serde_json)
 (synopsis "JSON format support for Serde")
 (depends
   (ocaml (>= "5.1.1"))
   (ppx_inline_test (>= "v0.16.0"))
   (qcheck :with-test)
   (rio (>= "0.0.8"))
   (serde (= :version))
   (serde_derive (= :version))
   (spices :with-test)
   (yojson (>= "2.1.0"))
   dune))
   
