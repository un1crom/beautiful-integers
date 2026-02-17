(* Beautiful Integers: Phase 1 research engine. *)

ClearAll[
  NormalizeText, OEISRecord, OEISBFileTerms, OEISInlineTerms, RecamanTerms,
  KolakoskiTerms, FallbackTerms, LoadTerms, Entropy01, Clamp01,
  CompressibilityScore, DeltaSignEntropyScore, GrowthDramaScore,
  ResidueStructureScore, NoveltyScore, BeautyProfile, SequenceLinePlot,
  SequenceDifferencePlot, ResidueArrayPlot, DigitTexturePlot,
  SignedLog, CircleLayoutCoords, SpiralLayoutCoords, EdgeWeightStyles,
  ModularTransitionGraphCircle, ModularTransitionGraphSpiral,
  ReturnMapPhasePlot, ResidueRecurrencePlot, DigitTransitionGraph,
  RasterizeGraphicImage, CoagulationCompositeImage, VisualHarmonyScore,
  CoagulationScore, IntegrateCoagulationIntoProfile,
  ImageStrikingnessScore, AtlasSelection, AnimationTermCounts,
  RenderAnimationFrame, CreateGraphDramaAnimations,
  RecamanArcPlot, KolakoskiRunLengthPlot, MakeVisuals, FormatMetric,
  CreateMarkdownReport, RunBeautifulResearch, SequenceCatalogData
];

SequenceCatalogData = {
  <|
    "ID" -> "A000045",
    "Label" -> "Fibonacci numbers",
    "HistoryNote" ->
      "Known in Indian prosody before Fibonacci's Liber Abaci; OEIS comments cite Gopala and Hemachandra traditions."
  |>,
  <|
    "ID" -> "A000040",
    "Label" -> "Prime numbers",
    "HistoryNote" ->
      "Central object of arithmetic since Euclid; OEIS notes include prime-number-theorem asymptotics."
  |>,
  <|
    "ID" -> "A000041",
    "Label" -> "Partition numbers",
    "HistoryNote" ->
      "The Hardy-Ramanujan circle method famously explains partition growth."
  |>,
  <|
    "ID" -> "A005132",
    "Label" -> "Recaman sequence",
    "HistoryNote" ->
      "Greedy self-avoiding rule creates dramatic jumps; OEIS highlights open behavior about missing values."
  |>,
  <|
    "ID" -> "A000002",
    "Label" -> "Kolakoski sequence",
    "HistoryNote" ->
      "Self-describing run-length sequence with unresolved density questions, as noted on OEIS."
  |>
};

NormalizeText[value_] := Which[
  StringQ[value], StringTrim[value],
  ListQ[value], StringTrim @ StringRiffle[NormalizeText /@ value, " "],
  True, ToString[value, InputForm]
];

OEISRecord[id_String] := Module[{url, json, results},
  url = "https://oeis.org/search?fmt=json&q=id:" <> id;
  json = Quiet @ Check[Import[url, "RawJSON"], $Failed];
  If[
    AssociationQ[json],
    results = Lookup[json, "results", {}];
    If[ListQ[results] && Length[results] > 0, First[results], Missing["NotAvailable"]],
    Missing["NotAvailable"]
  ]
];

OEISBFileTerms[id_String, n_Integer?Positive] := Module[
  {digits, url, lines, pairs, values},
  digits = StringReplace[id, StartOfString ~~ "A" -> ""];
  url = "https://oeis.org/" <> id <> "/b" <> digits <> ".txt";
  lines = Quiet @ Check[Import[url, "Lines"], $Failed];
  If[!ListQ[lines], Return[Missing["NotAvailable"]]];
  pairs = Flatten[
    StringCases[
      lines,
      RegularExpression["^\\s*(-?\\d+)\\s+(-?\\d+)"] -> {"$1", "$2"}
    ],
    1
  ];
  values = Quiet @ Check[ToExpression[pairs[[All, 2]]], $Failed];
  If[ListQ[values] && Length[values] > 0, Take[values, UpTo[n]], Missing["NotAvailable"]]
];

OEISInlineTerms[id_String, n_Integer?Positive] := Module[
  {record, dataText, values},
  record = OEISRecord[id];
  If[record === Missing["NotAvailable"], Return[Missing["NotAvailable"]]];
  dataText = Lookup[record, "data", Missing["NotAvailable"]];
  If[!StringQ[dataText], Return[Missing["NotAvailable"]]];
  values = Quiet @ Check[
    ToExpression @ StringSplit[StringReplace[dataText, " " -> ""], ","],
    $Failed
  ];
  If[ListQ[values] && Length[values] > 0, Take[values, UpTo[n]], Missing["NotAvailable"]]
];

RecamanTerms[n_Integer?Positive] := Module[
  {values = {0}, seen = <|0 -> True|>, candidate, step},
  Do[
    candidate = values[[-1]] - step;
    If[candidate < 0 || KeyExistsQ[seen, candidate], candidate = values[[-1]] + step];
    AppendTo[values, candidate];
    seen[candidate] = True;
    ,
    {step, 1, n - 1}
  ];
  values
];

KolakoskiTerms[n_Integer?Positive] := Module[
  {sequence = {1, 2, 2}, readIndex = 3, value = 1, runLength},
  If[n <= 3, Return[Take[sequence, n]]];
  While[Length[sequence] < n,
    runLength = sequence[[readIndex]];
    sequence = Join[sequence, ConstantArray[value, runLength]];
    value = 3 - value;
    readIndex += 1;
  ];
  Take[sequence, n]
];

FallbackTerms[id_String, n_Integer?Positive] := Switch[
  id,
  "A000045", Table[Fibonacci[k], {k, 0, n - 1}],
  "A000040", Prime /@ Range[n],
  "A000041", Table[PartitionsP[k], {k, 0, n - 1}],
  "A005132", RecamanTerms[n],
  "A000002", KolakoskiTerms[n],
  _, Missing["NotAvailable"]
];

LoadTerms[id_String, n_Integer?Positive] := Module[
  {bfileTerms, inlineTerms, fallbackTerms},
  bfileTerms = OEISBFileTerms[id, n];
  If[ListQ[bfileTerms] && Length[bfileTerms] >= n, Return[Take[bfileTerms, n]]];
  inlineTerms = OEISInlineTerms[id, n];
  If[ListQ[inlineTerms] && Length[inlineTerms] >= n, Return[Take[inlineTerms, n]]];
  fallbackTerms = FallbackTerms[id, n];
  If[ListQ[fallbackTerms], Return[Take[fallbackTerms, n]]];
  If[ListQ[inlineTerms] && Length[inlineTerms] > 0, Return[inlineTerms]];
  If[ListQ[bfileTerms] && Length[bfileTerms] > 0, Return[bfileTerms]];
  Missing["NotAvailable"]
];

Entropy01[counts_Association] := Module[{weights, probabilities, entropy, maxEntropy},
  weights = Values[counts];
  If[Length[weights] == 0 || Total[weights] == 0, Return[0.0]];
  probabilities = N[weights/Total[weights]];
  entropy = -Total[probabilities*Log[2, probabilities]];
  maxEntropy = Log[2, Length[probabilities]];
  If[maxEntropy == 0, 0.0, N[entropy/maxEntropy]]
];

Clamp01[x_] := N @ Clip[x, {0.0, 1.0}];

CompressibilityScore[data_List] := Module[{rawBytes, compressedBytes},
  rawBytes = ByteCount[data];
  compressedBytes = ByteCount[Compress[data]];
  If[rawBytes <= 0, 0.0, Clamp01[1.0 - compressedBytes/rawBytes]]
];

DeltaSignEntropyScore[data_List] := Module[{signs, counts},
  If[Length[data] < 3, Return[0.0]];
  signs = Sign[Differences[data]];
  counts = Counts[signs];
  Entropy01[counts]
];

GrowthDramaScore[data_List] := Module[{logMagnitudes, deltas, volatility},
  If[Length[data] < 3, Return[0.0]];
  logMagnitudes = Log[1 + Abs[data]];
  deltas = Differences[logMagnitudes];
  volatility = StandardDeviation[deltas];
  Clamp01[1.0 - Exp[-volatility]]
];

ResidueStructureScore[data_List, modulus : (_Integer?Positive) : 12] := Module[
  {residues, counts, normalizedEntropy},
  residues = Mod[data, modulus];
  counts = Counts[residues];
  normalizedEntropy = Entropy01[counts];
  Clamp01[1.0 - normalizedEntropy]
];

NoveltyScore[data_List] := If[Length[data] == 0, 0.0, N[Length[DeleteDuplicates[data]]/Length[data]]];

BeautyProfile[data_List, modulus : (_Integer?Positive) : 12] := Module[
  {
    compressibility, deltaEntropy, growthDrama, residueStructure, novelty,
    structuralBeauty
  },
  compressibility = CompressibilityScore[data];
  deltaEntropy = DeltaSignEntropyScore[data];
  growthDrama = GrowthDramaScore[data];
  residueStructure = ResidueStructureScore[data, modulus];
  novelty = NoveltyScore[data];
  structuralBeauty = Clamp01[
    0.34*compressibility + 0.28*deltaEntropy + 0.18*growthDrama +
    0.10*residueStructure + 0.10*novelty
  ];
  <|
    "Compressibility" -> compressibility,
    "DeltaSignEntropy" -> deltaEntropy,
    "GrowthDrama" -> growthDrama,
    "ResidueStructure" -> residueStructure,
    "Novelty" -> novelty,
    "StructuralBeauty" -> structuralBeauty,
    "CoagulationScore" -> 0.0,
    "BeautyIndex" -> structuralBeauty
  |>
];

SequenceLinePlot[id_String, label_String, data_List] := ListLinePlot[
  data,
  PlotTheme -> "Scientific",
  PlotRange -> All,
  ImageSize -> 720,
  AxesLabel -> {"n", "a(n)"},
  PlotLabel -> id <> " " <> label <> " (first " <> ToString[Length[data]] <> " terms)"
];

SequenceDifferencePlot[id_String, data_List] := If[
  Length[data] < 2,
  Graphics[Text["Need at least two terms"], ImageSize -> 720],
  ListLinePlot[
    Differences[data],
    PlotRange -> All,
    ImageSize -> 720,
    AxesLabel -> {"n", "a(n+1)-a(n)"},
    PlotStyle -> ColorData["DarkRainbow"][0.72],
    PlotLabel -> id <> " first differences"
  ]
];

ResidueArrayPlot[
  id_String,
  data_List,
  modulus : (_Integer?Positive) : 12,
  width : (_Integer?Positive) : 24
] := Module[
  {residues, rows, matrix},
  residues = Mod[data, modulus];
  rows = Ceiling[Length[residues]/width];
  matrix = Partition[PadRight[residues, rows*width, 0], width];
  ArrayPlot[
    matrix,
    Frame -> False,
    ImageSize -> 720,
    ColorFunction -> (ColorData["SolarColors"][#/Max[1.0, modulus - 1]] &),
    PlotLabel -> id <> " residues mod " <> ToString[modulus]
  ]
];

DigitTexturePlot[id_String, data_List, width : (_Integer?Positive) : 52] := Module[
  {digitCharacters, digits, rows, matrix},
  digitCharacters = Characters[StringJoin[IntegerString /@ Abs[data]]];
  digits = ToExpression[digitCharacters];
  rows = Ceiling[Length[digits]/width];
  matrix = Partition[PadRight[digits, rows*width, 0], width];
  ArrayPlot[
    matrix,
    Frame -> False,
    ImageSize -> 720,
    ColorFunction -> (ColorData["DeepSeaColors"][#/9.0] &),
    PlotLabel -> id <> " digit texture"
  ]
];

SignedLog[x_] := Sign[x]*Log[1 + N[Abs[x]]];

CircleLayoutCoords[n_Integer?Positive] := Association @ Table[
  i -> {Cos[2 Pi i/n], Sin[2 Pi i/n]},
  {i, 0, n}
];

SpiralLayoutCoords[n_Integer?Positive] := Association @ Table[
  i -> Module[{theta, radius},
    theta = 2 Pi i/Max[1.0, n/3.0];
    radius = 0.20 + 0.80*N[i/Max[1, n]];
    radius*{Cos[theta], Sin[theta]}
  ],
  {i, 0, n}
];

EdgeWeightStyles[counts_Association, colorScheme_String : "SolarColors"] := Module[
  {maxWeight},
  maxWeight = Max[1, Max[Values[counts]]];
  Association @ KeyValueMap[
    Function[{edge, weight},
      edge -> Directive[
        Opacity[0.12 + 0.80*N[weight/maxWeight]],
        AbsoluteThickness[0.45 + 2.60*N[weight/maxWeight]],
        ColorData[colorScheme][N[weight/maxWeight]]
      ]
    ],
    counts
  ]
];

ModularTransitionGraphCircle[
  id_String,
  data_List,
  modulus : (_Integer?Positive) : 97
] := Module[
  {nodeCount, mapped, edges, counts, styles, coords},
  If[Length[data] < 2, Return[Graphics[Text["Need at least two terms"], ImageSize -> 720]]];
  nodeCount = Max[8, modulus];
  mapped = Mod[data, nodeCount];
  edges = DirectedEdge @@@ Partition[mapped, 2, 1];
  counts = Counts[edges];
  styles = EdgeWeightStyles[counts, "AtlanticColors"];
  coords = CircleLayoutCoords[nodeCount - 1];
  Graph[
    Range[0, nodeCount - 1],
    Keys[counts],
    VertexCoordinates -> coords,
    EdgeStyle -> styles,
    VertexLabels -> None,
    VertexSize -> 0.16,
    VertexStyle -> Directive[
      GrayLevel[0.88],
      EdgeForm[Directive[GrayLevel[0.45], AbsoluteThickness[0.6]]]
    ],
    ImageSize -> 720,
    PlotLabel ->
      id <> " modular transition chords (circle, mod " <> ToString[nodeCount] <> ")",
    PerformanceGoal -> "Quality"
  ]
];

ModularTransitionGraphSpiral[
  id_String,
  data_List,
  modulus : (_Integer?Positive) : 97
] := Module[
  {nodeCount, mapped, edges, counts, styles, coords},
  If[Length[data] < 2, Return[Graphics[Text["Need at least two terms"], ImageSize -> 720]]];
  nodeCount = Max[8, modulus];
  mapped = Mod[data, nodeCount];
  edges = UndirectedEdge @@@ Partition[mapped, 2, 1];
  counts = Counts[edges];
  styles = EdgeWeightStyles[counts, "DarkRainbow"];
  coords = SpiralLayoutCoords[nodeCount - 1];
  Graph[
    Range[0, nodeCount - 1],
    Keys[counts],
    VertexCoordinates -> coords,
    EdgeStyle -> styles,
    VertexLabels -> None,
    VertexSize -> 0.14,
    VertexStyle -> Directive[
      GrayLevel[0.90],
      EdgeForm[Directive[GrayLevel[0.48], AbsoluteThickness[0.5]]]
    ],
    ImageSize -> 720,
    PlotLabel ->
      id <> " modular transitions (spiral, mod " <> ToString[nodeCount] <> ")",
    PerformanceGoal -> "Quality"
  ]
];

ReturnMapPhasePlot[id_String, data_List] := Module[{xVals, yVals},
  If[Length[data] < 2, Return[Graphics[Text["Need at least two terms"], ImageSize -> 720]]];
  xVals = SignedLog /@ Most[data];
  yVals = SignedLog /@ Rest[data];
  ListPlot[
    Transpose[{xVals, yVals}],
    PlotRange -> All,
    Axes -> False,
    Frame -> True,
    FrameLabel -> {"signed-log a(n)", "signed-log a(n+1)"},
    ImageSize -> 720,
    PlotStyle -> Directive[
      PointSize[0.012],
      Opacity[0.62],
      ColorData["SiennaTones"][0.73]
    ],
    PlotLabel -> id <> " return-map phase portrait"
  ]
];

ResidueRecurrencePlot[
  id_String,
  data_List,
  modulus : (_Integer?Positive) : 97
] := Module[
  {embeddingDim, transformed, embedded, distanceMatrix, scale},
  If[Length[data] < 8, Return[Graphics[Text["Need at least eight terms"], ImageSize -> 720]]];
  embeddingDim = Clip[Round[modulus/24], {3, 8}];
  transformed = SignedLog /@ data;
  embedded = Partition[transformed, embeddingDim, 1];
  distanceMatrix = Outer[EuclideanDistance, embedded, embedded, 1];
  scale = Max[10^-9, Quantile[Flatten[distanceMatrix], 0.88]];
  ArrayPlot[
    distanceMatrix,
    Frame -> False,
    ImageSize -> 720,
    ColorFunction -> (ColorData["AvocadoColors"][1.0 - Clip[N[#/scale], {0.0, 1.0}]] &),
    PlotLabel -> id <> " delay-embedding recurrence texture"
  ]
];

DigitTransitionGraph[id_String, data_List] := Module[
  {digitChars, digits, edges, counts, styles, coords},
  digitChars = Characters[StringJoin[IntegerString /@ Abs[data]]];
  If[Length[digitChars] < 2, Return[Graphics[Text["Need at least two digits"], ImageSize -> 720]]];
  digits = ToExpression[digitChars];
  edges = DirectedEdge @@@ Partition[digits, 2, 1];
  counts = Counts[edges];
  styles = EdgeWeightStyles[counts, "RoseColors"];
  coords = Association @ Table[d -> {Cos[2 Pi d/10], Sin[2 Pi d/10]}, {d, 0, 9}];
  Graph[
    Range[0, 9],
    Keys[counts],
    VertexCoordinates -> coords,
    EdgeStyle -> styles,
    VertexLabels -> "Name",
    VertexLabelStyle -> Directive[Black, 11, Bold],
    VertexSize -> 0.36,
    VertexStyle -> Directive[
      White,
      EdgeForm[Directive[GrayLevel[0.35], AbsoluteThickness[0.8]]]
    ],
    ImageSize -> 720,
    PlotLabel -> id <> " digit-transition network",
    PerformanceGoal -> "Quality"
  ]
];

RasterizeGraphicImage[graphic_, size : (_Integer?Positive) : 640] := Module[{img},
  img = Quiet @ Check[Rasterize[graphic, "Image", RasterSize -> size], $Failed];
  If[Head[img] === Image, img, $Failed]
];

CoagulationCompositeImage[id_String, visuals_Association] := Module[
  {priority, selectedKeys, imgs, blank, tiles},
  priority = {
    "line", "difference", "phase", "residue", "recurrence",
    "mod-circle", "mod-spiral", "digitgraph", "digits", "arcs", "runs"
  };
  selectedKeys = Take[Select[priority, KeyExistsQ[visuals, #] &], UpTo[9]];
  imgs = DeleteCases[RasterizeGraphicImage[visuals[#], 560] & /@ selectedKeys, $Failed];
  blank = Image[
    ConstantArray[{0.07, 0.07, 0.08}, {360, 360}],
    "Real",
    ColorSpace -> "RGB"
  ];
  tiles = PadRight[
    (ImageResize[ColorConvert[#, "RGB"], {360, 360}] &) /@ imgs,
    9,
    blank
  ];
  ImageAssemble[Partition[tiles, 3], Background -> RGBColor[0.06, 0.06, 0.07]]
];

VisualHarmonyScore[visuals_Association] := Module[
  {priority, keys, imgs, n, pairwise},
  priority = {"line", "difference", "phase", "recurrence", "mod-circle", "mod-spiral", "digitgraph"};
  keys = Take[Select[priority, KeyExistsQ[visuals, #] &], UpTo[6]];
  imgs = DeleteCases[RasterizeGraphicImage[visuals[#], 340] & /@ keys, $Failed];
  imgs = ImageResize[ColorConvert[#, "Grayscale"], {240, 240}] & /@ imgs;
  n = Length[imgs];
  If[n < 2, Return[0.5]];
  pairwise = Flatten @ Table[
    Clip[
      1.0 - Quiet @ Check[
        N @ ImageDistance[
          imgs[[i]],
          imgs[[j]],
          Method -> "NormalizedSquaredEuclideanDistance"
        ],
        1.0
      ],
      {0.0, 1.0}
    ],
    {i, 1, n - 1},
    {j, i + 1, n}
  ];
  Clamp01[Mean[pairwise]]
];

CoagulationScore[coagImage_Image, visuals_Association] := Module[
  {striking, harmony, symmetry},
  striking = ImageStrikingnessScore[coagImage];
  harmony = VisualHarmonyScore[visuals];
  symmetry = Clip[
    1.0 - Quiet @ Check[
      N @ ImageDistance[
        ColorConvert[coagImage, "Grayscale"],
        ColorConvert[ImageReflect[coagImage, Left -> Right], "Grayscale"],
        Method -> "NormalizedSquaredEuclideanDistance"
      ],
      1.0
    ],
    {0.0, 1.0}
  ];
  Clamp01[0.50*striking + 0.35*harmony + 0.15*symmetry]
];

IntegrateCoagulationIntoProfile[profile_Association, coagScore_] := Module[
  {structural, beauty},
  structural = Lookup[profile, "StructuralBeauty", 0.0];
  beauty = Clamp01[0.72*coagScore + 0.28*structural];
  Join[profile, <|"CoagulationScore" -> coagScore, "BeautyIndex" -> beauty|>]
];

ImageStrikingnessScore[graphic_] := Module[
  {image, gray, rgbData, entropy, contrast, edgeDensity, colorSpread},
  image = Quiet @ Check[Rasterize[graphic, "Image", RasterSize -> 640], $Failed];
  If[Head[image] =!= Image, Return[0.0]];
  gray = ColorConvert[image, "Grayscale"];
  entropy = Quiet @ Check[N @ ImageMeasurements[gray, "Entropy"], 0.0];
  contrast = Quiet @ Check[StandardDeviation[Flatten @ ImageData[gray]], 0.0];
  edgeDensity = Quiet @ Check[
    Mean @ Flatten @ ImageData @ Binarize[EdgeDetect[gray, 2], 0.23],
    0.0
  ];
  rgbData = Quiet @ Check[Flatten[ImageData[ColorConvert[image, "RGB"]], 1], {}];
  colorSpread = If[Length[rgbData] == 0, 0.0, Mean[StandardDeviation /@ Transpose[rgbData]]];
  Clamp01[
    0.30*(1.0 - Exp[-entropy/6.5]) +
    0.25*Clip[contrast*4.2, {0.0, 1.0}] +
    0.25*Clip[edgeDensity*6.0, {0.0, 1.0}] +
    0.20*Clip[colorSpread*6.0, {0.0, 1.0}]
  ]
];

AtlasSelection[visuals_Association] := Module[
  {baseScores, boostedScores, bestName},
  baseScores = Association @ KeyValueMap[
    Function[{name, graphic}, name -> ImageStrikingnessScore[graphic]],
    visuals
  ];
  boostedScores = Association @ KeyValueMap[
    Function[{name, score},
      name -> (score + If[
        MemberQ[{"coagulation", "mod-spiral", "mod-circle", "recurrence", "digitgraph", "arcs"}, name],
        0.07,
        0.0
      ])
    ],
    baseScores
  ];
  bestName = First @ First @ ReverseSortBy[Normal[boostedScores], Last];
  <|
    "BestView" -> bestName,
    "BestScore" -> Lookup[boostedScores, bestName, 0.0],
    "Scores" -> boostedScores
  |>
];

AnimationTermCounts[
  termCount : (_Integer?Positive),
  frameCount : (_Integer?Positive) : 12,
  minTerms : (_Integer?Positive) : 24
] := Module[{counts},
  counts = Round @ Subdivide[minTerms, termCount, Max[2, frameCount] - 1];
  counts = DeleteDuplicates @ Select[counts, 2 <= # <= termCount &];
  If[Length[counts] == 0, counts = {termCount}];
  If[Last[counts] =!= termCount, counts = Append[counts, termCount]];
  counts
];

RenderAnimationFrame[graphic_] := Module[{image},
  image = Quiet @ Check[Rasterize[graphic, "Image", RasterSize -> 1000], $Failed];
  If[
    Head[image] === Image,
    image,
    Rasterize[
      Graphics[
        Inset[Style["frame render failed", 16, Red]],
        PlotRange -> {{0, 1}, {0, 1}},
        Background -> GrayLevel[0.1],
        ImageSize -> 720
      ],
      "Image",
      RasterSize -> 1000
    ]
  ]
];

CreateGraphDramaAnimations[
  id_String,
  terms_List,
  outputDir_String,
  frameCount : (_Integer?Positive) : 12,
  minTerms : (_Integer?Positive) : 24
] := Module[
  {
    counts, circleFrames, spiralFrames, circleImages, spiralImages,
    circleGifFile, spiralGifFile, circleMP4File, spiralMP4File,
    graphModulus, animationFiles, videoReadyQ
  },
  videoReadyQ[file_] := FileExistsQ[file] && Quiet @ Check[FileByteCount[file] > 0, False];
  counts = AnimationTermCounts[Length[terms], frameCount, minTerms];
  circleFrames = Table[
    graphModulus = Max[24, Min[97, Round[k/2.5]]];
    ModularTransitionGraphCircle[id, Take[terms, k], graphModulus],
    {k, counts}
  ];
  spiralFrames = Table[
    graphModulus = Max[24, Min[97, Round[k/2.5]]];
    ModularTransitionGraphSpiral[id, Take[terms, k], graphModulus],
    {k, counts}
  ];
  circleImages = RenderAnimationFrame /@ circleFrames;
  spiralImages = RenderAnimationFrame /@ spiralFrames;
  circleImages = ImageResize[#, {1000, 1000}] & /@ circleImages;
  spiralImages = ImageResize[#, {1000, 1000}] & /@ spiralImages;
  circleGifFile = FileNameJoin[{outputDir, id <> "-drama-circle.gif"}];
  spiralGifFile = FileNameJoin[{outputDir, id <> "-drama-spiral.gif"}];
  circleMP4File = FileNameJoin[{outputDir, id <> "-drama-circle.mp4"}];
  spiralMP4File = FileNameJoin[{outputDir, id <> "-drama-spiral.mp4"}];

  Export[
    circleGifFile,
    circleImages,
    "GIF",
    "DisplayDurations" -> ConstantArray[0.40, Length[circleFrames]],
    "AnimationRepetitions" -> Infinity
  ];
  Export[
    spiralGifFile,
    spiralImages,
    "GIF",
    "DisplayDurations" -> ConstantArray[0.40, Length[spiralFrames]],
    "AnimationRepetitions" -> Infinity
  ];

  Quiet @ Check[
    Export[
      circleMP4File,
      circleImages,
      "MP4",
      "FrameRate" -> 8
    ],
    $Failed
  ];
  If[!videoReadyQ[circleMP4File],
    Quiet @ Check[
      Export[
        circleMP4File,
        Video[circleImages, "FrameRate" -> 8],
        "MP4"
      ],
      $Failed
    ];
  ];
  Quiet @ Check[
    Export[
      spiralMP4File,
      spiralImages,
      "MP4",
      "FrameRate" -> 8
    ],
    $Failed
  ];
  If[!videoReadyQ[spiralMP4File],
    Quiet @ Check[
      Export[
        spiralMP4File,
        Video[spiralImages, "FrameRate" -> 8],
        "MP4"
      ],
      $Failed
    ];
  ];

  animationFiles = <|
    "drama-circle-gif" -> circleGifFile,
    "drama-spiral-gif" -> spiralGifFile
  |>;
  If[videoReadyQ[circleMP4File], AssociateTo[animationFiles, "drama-circle-mp4" -> circleMP4File]];
  If[videoReadyQ[spiralMP4File], AssociateTo[animationFiles, "drama-spiral-mp4" -> spiralMP4File]];
  animationFiles
];

RecamanArcPlot[data_List, maxSteps : (_Integer?Positive) : 140] := Module[
  {pairs, arcs},
  pairs = Take[Partition[data, 2, 1], UpTo[maxSteps]];
  arcs = MapIndexed[
    Function[{pair, idx},
      Module[{a, b, center, radius, theta},
        a = pair[[1]];
        b = pair[[2]];
        center = N[(a + b)/2.0];
        radius = N[Abs[b - a]/2.0];
        theta = If[OddQ[idx[[1]]], {0, Pi}, {Pi, 2 Pi}];
        {
          Directive[
            AbsoluteThickness[1.2],
            Opacity[0.78],
            ColorData["SunsetColors"][N[idx[[1]]/Max[1, Length[pairs]]]]
          ],
          Circle[{center, 0}, radius, theta]
        }
      ]
    ],
    pairs
  ];
  Graphics[
    arcs,
    Axes -> {True, False},
    PlotRange -> All,
    ImageSize -> 720,
    PlotLabel -> "A005132 Recaman arc portrait"
  ]
];

KolakoskiRunLengthPlot[data_List] := Module[{runLengths},
  runLengths = Length /@ Split[data];
  ListLinePlot[
    runLengths,
    PlotRange -> All,
    ImageSize -> 720,
    AxesLabel -> {"run index", "run length"},
    PlotStyle -> ColorData["RoseColors"][0.65],
    PlotLabel -> "A000002 run-length profile"
  ]
];

MakeVisuals[
  id_String,
  label_String,
  terms_List,
  modulus : (_Integer?Positive) : 12,
  width : (_Integer?Positive) : 24
] := Module[{visuals, graphModulus},
  graphModulus = Max[24, Min[97, Round[Length[terms]/2.5]]];
  visuals = <|
    "line" -> SequenceLinePlot[id, label, terms],
    "difference" -> SequenceDifferencePlot[id, terms],
    "residue" -> ResidueArrayPlot[id, terms, modulus, width],
    "digits" -> DigitTexturePlot[id, terms],
    "phase" -> ReturnMapPhasePlot[id, terms],
    "recurrence" -> ResidueRecurrencePlot[id, terms, graphModulus],
    "mod-circle" -> ModularTransitionGraphCircle[id, terms, graphModulus],
    "mod-spiral" -> ModularTransitionGraphSpiral[id, terms, graphModulus],
    "digitgraph" -> DigitTransitionGraph[id, terms]
  |>;
  If[id == "A005132", AssociateTo[visuals, "arcs" -> RecamanArcPlot[terms]]];
  If[id == "A000002", AssociateTo[visuals, "runs" -> KolakoskiRunLengthPlot[terms]]];
  visuals
];

FormatMetric[x_] := ToString @ NumberForm[N[x], {Infinity, 3}, NumberPadding -> {"", "0"}];

CreateMarkdownReport[records_List, outputDir_String] := Module[
  {ranked, lines, reportPath},
  ranked = ReverseSortBy[
    Select[records, Lookup[#, "Status", "Failed"] == "OK" &],
    Lookup[Lookup[#, "Profile", <||>], "BeautyIndex", 0.0] &
  ];
  lines = Join[
    {
      "# Beautiful Integers: Phase 1",
      "",
      "Generated: " <> DateString[Now, {"Year", "-", "Month", "-", "Day", " ", "Hour", ":", "Minute"}],
      "",
      "## Ranking by BeautyIndex",
      ""
    },
    Flatten @ MapIndexed[
      Function[{record, idx},
        {
          ToString[idx[[1]]] <> ". " <> record["ID"] <> " - " <> record["Label"],
          "   BeautyIndex=" <> FormatMetric[record["Profile"]["BeautyIndex"]] <>
            " | CoagulationScore=" <> FormatMetric[record["Profile"]["CoagulationScore"]] <>
            " | StructuralBeauty=" <> FormatMetric[record["Profile"]["StructuralBeauty"]] <>
            " | Compressibility=" <> FormatMetric[record["Profile"]["Compressibility"]] <>
            " | DeltaSignEntropy=" <> FormatMetric[record["Profile"]["DeltaSignEntropy"]] <>
            " | GrowthDrama=" <> FormatMetric[record["Profile"]["GrowthDrama"]] <>
            " | ResidueStructure=" <> FormatMetric[record["Profile"]["ResidueStructure"]] <>
            " | Novelty=" <> FormatMetric[record["Profile"]["Novelty"]],
          "   OEIS: https://oeis.org/" <> record["ID"],
          "   History: " <> record["HistoryNote"],
          "   Atlas: " <>
            Lookup[Lookup[record, "Atlas", <||>], "BestView", "n/a"] <>
            " (score=" <> FormatMetric[Lookup[Lookup[record, "Atlas", <||>], "BestScore", 0.0]] <> ")",
          "   AtlasImage: " <> Lookup[Lookup[record, "ImageFiles", <||>], "atlas", "n/a"],
          If[
            Length[Lookup[record, "AnimationFiles", <||>]] > 0,
            "   Animations: " <> StringRiffle[Values[record["AnimationFiles"]], " | "],
            "   Animations: none"
          ],
          ""
        }
      ],
      ranked
    ]
  ];
  reportPath = FileNameJoin[{outputDir, "beauty-report.md"}];
  Export[reportPath, StringRiffle[lines, "\n"], "Text"];
  reportPath
];

Options[RunBeautifulResearch] = {
  "TermCount" -> 220,
  "Modulus" -> 12,
  "GridWidth" -> 24,
  "AnimationFrames" -> 12,
  "AnimationMinTerms" -> 24,
  "EnableAnimations" -> True,
  "OutputDirectory" -> Automatic
};

RunBeautifulResearch[OptionsPattern[]] := Module[
  {
    termCount, modulus, gridWidth, outputDir, animationFrames, animationMinTerms,
    enableAnimations, records, summaryJSON,
    summaryWL, summaryTXT, rankedIDs, reportPath
  },
  termCount = OptionValue["TermCount"];
  modulus = OptionValue["Modulus"];
  gridWidth = OptionValue["GridWidth"];
  animationFrames = OptionValue["AnimationFrames"];
  animationMinTerms = OptionValue["AnimationMinTerms"];
  enableAnimations = TrueQ[OptionValue["EnableAnimations"]];
  outputDir = OptionValue["OutputDirectory"];
  If[outputDir === Automatic, outputDir = FileNameJoin[{Directory[], "outputs"}]];
  If[!DirectoryQ[outputDir], CreateDirectory[outputDir, CreateIntermediateDirectories -> True]];

  records = Reap[
    Do[
      Module[
        {
          id, label, historyNote, terms, record, profile, visuals, imageFiles,
          oeis, atlas, atlasFile, animationFiles, coagulationImage, coagulationScore
        },
        id = config["ID"];
        label = config["Label"];
        historyNote = config["HistoryNote"];
        Print["Processing ", id, " (", label, ") ..."];

        terms = LoadTerms[id, termCount];
        If[!ListQ[terms] || Length[terms] < 20,
          Sow[<|"ID" -> id, "Label" -> label, "HistoryNote" -> historyNote, "Status" -> "FailedToLoad"|>];
          Continue[];
        ];

        profile = BeautyProfile[terms, modulus];
        visuals = MakeVisuals[id, label, terms, modulus, gridWidth];
        coagulationImage = CoagulationCompositeImage[id, visuals];
        AssociateTo[visuals, "coagulation" -> coagulationImage];
        coagulationScore = CoagulationScore[coagulationImage, visuals];
        profile = IntegrateCoagulationIntoProfile[profile, coagulationScore];

        atlas = AtlasSelection[visuals];
        atlasFile = Export[
          FileNameJoin[{outputDir, id <> "-atlas.png"}],
          visuals[atlas["BestView"]],
          "PNG",
          ImageResolution -> 180
        ];

        animationFiles = If[
          enableAnimations,
          CreateGraphDramaAnimations[id, terms, outputDir, animationFrames, animationMinTerms],
          <||>
        ];

        imageFiles = Association @ KeyValueMap[
          Function[{name, graphic},
            name -> Export[
              FileNameJoin[{outputDir, id <> "-" <> name <> ".png"}],
              graphic,
              "PNG",
              ImageResolution -> 180
            ]
          ],
          visuals
        ];
        AssociateTo[imageFiles, "atlas" -> atlasFile];

        oeis = OEISRecord[id];
        record = <|
          "ID" -> id,
          "Label" -> label,
          "HistoryNote" -> historyNote,
          "Status" -> "OK",
          "OEISName" -> If[AssociationQ[oeis], NormalizeText[Lookup[oeis, "name", ""]], ""],
          "OEISComment" -> If[AssociationQ[oeis], NormalizeText[Lookup[oeis, "comment", ""]], ""],
          "Terms" -> terms,
          "Profile" -> profile,
          "ImageFiles" -> imageFiles,
          "Atlas" -> atlas,
          "AnimationFiles" -> animationFiles
        |>;
        Sow[record];
      ],
      {config, SequenceCatalogData}
    ]
  ][[2, 1]];

  reportPath = CreateMarkdownReport[records, outputDir];

  rankedIDs = Map[
    Lookup[#, "ID", "Unknown"] &,
    ReverseSortBy[
      Select[records, Lookup[#, "Status", "Failed"] == "OK" &],
      Lookup[Lookup[#, "Profile", <||>], "BeautyIndex", 0.0] &
    ]
  ];

  summaryJSON = Map[
    Function[record,
      <|
        "id" -> Lookup[record, "ID", "Unknown"],
        "label" -> Lookup[record, "Label", "Unknown"],
        "status" -> Lookup[record, "Status", "Failed"],
        "oeis_name" -> Lookup[record, "OEISName", ""],
        "history_note" -> Lookup[record, "HistoryNote", ""],
        "beauty_profile" -> Normal @ Lookup[record, "Profile", <||>],
        "atlas_view" -> Lookup[Lookup[record, "Atlas", <||>], "BestView", ""],
        "atlas_score" -> Lookup[Lookup[record, "Atlas", <||>], "BestScore", 0.0],
        "atlas_scores" -> Normal @ Lookup[Lookup[record, "Atlas", <||>], "Scores", <||>],
        "first_terms" -> If[ListQ[Lookup[record, "Terms", Missing["NotAvailable"]]],
          Take[record["Terms"], UpTo[30]],
          {}
        ],
        "image_files" -> Normal @ Lookup[record, "ImageFiles", <||>],
        "animation_files" -> Normal @ Lookup[record, "AnimationFiles", <||>]
      |>
    ],
    records
  ];

  summaryWL = <|
    "GeneratedAt" -> DateString[Now, {"ISODate", " ", "Hour", ":", "Minute", ":", "Second"}],
    "Parameters" -> <|
      "TermCount" -> termCount,
      "Modulus" -> modulus,
      "GridWidth" -> gridWidth,
      "AnimationFrames" -> animationFrames,
      "AnimationMinTerms" -> animationMinTerms,
      "EnableAnimations" -> enableAnimations
    |>,
    "RankedIDs" -> rankedIDs,
    "ReportPath" -> reportPath,
    "Records" -> records
  |>;

  summaryTXT = StringRiffle[
    {
      "Beautiful Integers Phase 1 complete.",
      "Output directory: " <> outputDir,
      "Report: " <> reportPath,
      "Ranked IDs: " <> StringRiffle[rankedIDs, ", "],
      "Atlas + drama animations generated for all successful sequences."
    },
    "\n"
  ];

  Export[FileNameJoin[{outputDir, "summary.json"}], summaryJSON, "JSON"];
  Export[FileNameJoin[{outputDir, "summary.wl"}], summaryWL, "WL"];
  Export[FileNameJoin[{outputDir, "summary.txt"}], summaryTXT, "Text"];

  summaryWL
];
