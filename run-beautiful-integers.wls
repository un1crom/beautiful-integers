SetDirectory[DirectoryName[$InputFileName]];
Get["beautiful-integers.wl"];
result = RunBeautifulResearch[
  "TermCount" -> 240,
  "Modulus" -> 12,
  "GridWidth" -> 24
];
Print[result];
