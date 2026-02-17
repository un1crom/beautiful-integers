SetDirectory[DirectoryName[$InputFileName]];
Get["beautiful-integers.wl"];
result = RunBeautifulResearch[
  "TermCount" -> 240,
  "Modulus" -> 12,
  "GridWidth" -> 24
];
Print["Ranked IDs: ", StringRiffle[result["RankedIDs"], ", "]];
Print["Report: ", result["ReportPath"]];
