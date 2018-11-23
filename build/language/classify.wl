(* ::Package:: *)

<< (NotebookDirectory[] <> "../dist/wldata.mx");
<< (NotebookDirectory[] <> "utilities.wl");


$dataset = Association[wl`documentedLists];
AssociateTo[$dataset, "built_in_undocumented_symbols" -> wl`usageAbsentSymbols];


classify[usages_, func_Function] := Last @ Reap[
	Sow[Keys[#], func[Values[#]]] & /@ usages,
	_String,
	Rule
] // (AssociateTo[$dataset, #]; #) &;

classify[usages_, rules_Association] := classify[usages,
	Function[usage, Piecewise @ KeyValueMap[{#1, #2[usage]} &, rules]]
];


classifiedNamespace = classify[Keys[#] -> ("Definition" /. Values[#]) & /@ wl`usageDictionary, <|
	"built_in_functions" -> StringStartsQ["\!\(\*RowBox[{"],
	"built_in_options" -> StringContainsQ[RegularExpression["is an? (\\w+ )?option"]],
	"built_in_constants" -> (True &)
|>];


getLines[name_] := Select[StringStartsQ[
	"\!\(\*RowBox[{" ~~ ("\"" | "") ~~ name
]] @ StringCases[RegularExpression["(\!\(\*([^\)]+)\)|.)+"]][
	"Definition" /. (name /. wl`usageDictionary)
];

getArguments[usage_] := usage //
	StringCases[#, RegularExpression["\!\(\*([^\)]+)\)"] -> "$1", 1]& //
	First //
	ToExpression //
	util`getAtomic[{1}] //
	If[Length[#] <= 3, {}, util`getAtomic[{3, 1}][#]]& //
	If[ListQ[#], util`getAtomic[{1}] /@ Take[#, {1, -1, 2}], {#}]&;

functionArguments = util`ruleMap[
	getArguments /@ getLines[#]&,
	"built_in_functions" /. classifiedNamespace
];


testOne[crit_] := Length[#] > 0 && AllTrue[#, crit] &;
testAll[crit_, sel_: Identity] := testOne[Length[#] > 0 && crit[sel[#]] &];
isFunctional[arg_] := arg === "f" || arg === "crit" || arg === "test";

classify[functionArguments, <|
	"functional_first_param" -> testAll[isFunctional, First],
	"functional_last_param" -> testAll[isFunctional, Last]
|>];


classify[Keys[#] -> "LocalVariables" /. Values[#] & /@ wl`usageDictionary,
	If[MatchQ[#, {_String, _List}],
		"local_variables_" <> With[{pos = #[[2]]},
			If[Length[pos] == 1,
				"at_" <> ToString[pos[[1]]],
				"from_" <> ToString[pos[[1]]] <> "_to_" <> ToString[pos[[2]]]
			]
		],
		Null
	] &
];


Export[util`resolveFileName["../../dist/macros.json"], $dataset];


Export[util`resolveFileName["../../dist/namespace.json"], wl`namespace];


Export[util`resolveFileName["../../dist/usages.json"], Keys[#] -> ("Definition" /. Values[#]) & /@ wl`usageDictionary];
