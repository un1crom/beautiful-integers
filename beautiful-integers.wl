(* Beautiful Integers: Phase 1 research engine. *)

ClearAll[
  NormalizeText, OEISRecord, OEISBFileTerms, OEISInlineTerms, RecamanTerms,
  KolakoskiTerms, FallbackTerms, LoadTerms, Entropy01, Clamp01,
  CompressibilityScore, DeltaSignEntropyScore, GrowthDramaScore,
  ResidueStructureScore, NoveltyScore, SafeRescale01, MassEntropyScore,
  SequenceCompositionGeometry, CompositionGuideScores, CompositionAvoidPenalties,
  CompositionPowerProfile, BeautyProfile, SequenceLinePlot,
  SequenceDifferencePlot, ResidueArrayPlot, DigitTexturePlot,
  SignedLog, CircleLayoutCoords, SpiralLayoutCoords, EdgeWeightStyles,
  ModularTransitionGraphCircle, ModularTransitionGraphSpiral,
  ReturnMapPhasePlot, ResidueRecurrencePlot, DigitTransitionGraph,
  RasterizeGraphicImage, CoagulationCompositeImage, CoagulationBlendImage, VisualHarmonyScore,
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

Entropy01[counts_Association] := Module[{weights, probabilities, positiveProbabilities, entropy, maxEntropy},
  weights = Values[counts];
  If[Length[weights] == 0 || Total[weights] == 0, Return[0.0]];
  probabilities = N[weights/Total[weights]];
  positiveProbabilities = Select[probabilities, # > 0 &];
  entropy = If[Length[positiveProbabilities] == 0, 0.0, -Total[positiveProbabilities*Log[2, positiveProbabilities]]];
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

SafeRescale01[data_List] := Module[{min, max, span},
  If[Length[data] == 0, Return[{}]];
  min = N[Min[data]];
  max = N[Max[data]];
  span = max - min;
  If[span <= 10^-12, ConstantArray[0.5, Length[data]], N[(data - min)/span]]
];

MassEntropyScore[weights_List] := Module[{positive},
  positive = N[Clip[weights, {0.0, Infinity}]];
  If[Length[positive] == 0 || Total[positive] <= 10^-12, Return[0.0]];
  Entropy01[AssociationThread[Range[Length[positive]], positive]]
];

SequenceCompositionGeometry[data_List, grid : (_Integer?Positive) : 9] := Module[
  {
    n, x, y, gridN, xBin, yBin, cells, matrix, total, colMass, rowMass,
    center, centerRows, centerCols, centerMassRaw, centerMass,
    centerRowMass, centerColMass, leftMass, rightMass, topMass, bottomMass,
    innerMass, edgeMass, edgeWidth, leftEdgeIdx, bottomEdgeIdx,
    leftEdgeMass, bottomEdgeMass, cornerMass, lEdgeMass, occupiedFraction,
    rowEntropy, columnEntropy, verticalEntropy, phase, phaseOffsets, phaseR,
    phaseTheta, phaseAngleEntropy, phaseCov, phaseEigs, phaseIsotropy,
    meanRadius, phaseRingTightness, phaseRadiusSpan, centerAnchor,
    dy, ddy, slopeEntropy, inflections, curvatureVolatility, peakCount,
    peakIdx, peakGaps, peakGapCV, peakYSpread, thirdBins, thirdFractions,
    thirdBalance, apexIndex, apexX, leftPart, rightPart, leftRisingRatio,
    rightFallingRatio, diag1, diag2, diagonalAlignment, crossMass,
    leftRightBalance, topBottomBalance, leftRightImbalance, minorSideFraction,
    safeReal
  },
  safeReal[value_, default_ : 0.0] := Module[{n},
    n = Quiet @ Check[N[value], default];
    Which[
      !NumericQ[n], default,
      MatchQ[n, Indeterminate | ComplexInfinity | DirectedInfinity[_] | Infinity | -Infinity], default,
      Head[n] === Complex && !PossibleZeroQ[Im[n]], default,
      True, N[Re[n]]
    ]
  ];
  n = Length[data];
  If[n == 0,
    Return[
      <|
        "LeftRightBalance" -> 0.0,
        "TopBottomBalance" -> 0.0,
        "LeftRightImbalance" -> 0.0,
        "MinorSideFraction" -> 0.0,
        "CenterMassFraction" -> 0.0,
        "CenterRowMassFraction" -> 0.0,
        "CenterColumnMassFraction" -> 0.0,
        "EdgeMassFraction" -> 0.0,
        "LEdgeMassFraction" -> 0.0,
        "TopMassFraction" -> 0.0,
        "DominantCellFraction" -> 0.0,
        "OccupiedFraction" -> 0.0,
        "RowEntropy" -> 0.0,
        "ColumnEntropy" -> 0.0,
        "VerticalEntropy" -> 0.0,
        "SlopeEntropy" -> 0.0,
        "InflectionCount" -> 0,
        "CurvatureVolatility" -> 0.0,
        "PeakGapCV" -> 1.0,
        "PeakYSpread" -> 0.0,
        "ThirdBalance" -> 0.0,
        "ApexX" -> 0.5,
        "LeftRisingRatio" -> 0.0,
        "RightFallingRatio" -> 0.0,
        "DiagonalAlignment" -> 0.0,
        "CrossMassFraction" -> 0.0,
        "PhaseAngleEntropy" -> 0.0,
        "PhaseIsotropy" -> 0.0,
        "PhaseRingTightness" -> 0.0,
        "PhaseRadiusSpan" -> 0.0,
        "CenterAnchor" -> 0.0
      |>
    ]
  ];

  x = SafeRescale01[Range[n]];
  y = SafeRescale01[SignedLog /@ data];
  gridN = If[OddQ[grid], Max[5, grid], Max[5, grid + 1]];
  xBin = Clip[1 + Floor[x*(gridN - 10^-8)], {1, gridN}];
  yBin = Clip[1 + Floor[(1.0 - y)*(gridN - 10^-8)], {1, gridN}];
  cells = Counts[Transpose[{yBin, xBin}]];
  matrix = Normal @ SparseArray[KeyValueMap[#1 -> #2 &, cells], {gridN, gridN}, 0.0];
  total = Max[1.0, N[Total[Flatten[matrix]]]];

  colMass = N[Total[matrix]];
  rowMass = N[Total /@ matrix];
  center = Ceiling[gridN/2];
  centerRows = Select[Range[center - 1, center + 1], 1 <= # <= gridN &];
  centerCols = Select[Range[center - 1, center + 1], 1 <= # <= gridN &];
  centerMassRaw = N[Total[Flatten[matrix[[centerRows, centerCols]]]]];
  centerMass = centerMassRaw/total;
  centerRowMass = N[Total[rowMass[[centerRows]]]]/total;
  centerColMass = N[Total[colMass[[centerCols]]]]/total;

  leftMass = N[Total[colMass[[1 ;; Floor[gridN/2]]]]];
  rightMass = N[Total[colMass[[Ceiling[gridN/2] + 1 ;; gridN]]]];
  topMass = N[Total[rowMass[[1 ;; Floor[gridN/2]]]]];
  bottomMass = N[Total[rowMass[[Ceiling[gridN/2] + 1 ;; gridN]]]];

  innerMass = If[
    gridN > 2,
    N[Total[Flatten[matrix[[2 ;; gridN - 1, 2 ;; gridN - 1]]]]],
    0.0
  ];
  edgeMass = N[total - innerMass];
  edgeWidth = Max[1, Round[gridN/5]];
  leftEdgeIdx = Range[1, edgeWidth];
  bottomEdgeIdx = Range[gridN - edgeWidth + 1, gridN];
  leftEdgeMass = N[Total[colMass[[leftEdgeIdx]]]];
  bottomEdgeMass = N[Total[rowMass[[bottomEdgeIdx]]]];
  cornerMass = N[Total[Flatten[matrix[[bottomEdgeIdx, leftEdgeIdx]]]]];
  lEdgeMass = (leftEdgeMass + bottomEdgeMass - cornerMass)/total;

  occupiedFraction = N[Count[Flatten[matrix], _?(# > 0 &)]/(gridN*gridN)];
  rowEntropy = MassEntropyScore[rowMass];
  columnEntropy = MassEntropyScore[colMass];
  verticalEntropy = rowEntropy;

  phase = If[n >= 2, Transpose[{Most[y], Rest[y]}], {}];
  phaseOffsets = N[(# - {0.5, 0.5}) & /@ phase];
  phaseR = Norm /@ phaseOffsets;
  phaseTheta = If[Length[phaseOffsets] == 0, {}, Map[ArcTan[#[[1]], #[[2]]] &, phaseOffsets]];
  phaseAngleEntropy = If[
    Length[phaseTheta] < 4,
    0.0,
    safeReal[Entropy01 @ Counts[Clip[1 + Floor[(phaseTheta + Pi)/(2 Pi/12)], {1, 12}]], 0.0]
  ];
  phaseCov = If[
    Length[phaseOffsets] < 2,
    {{0.0, 0.0}, {0.0, 0.0}},
    Quiet @ Check[Covariance[phaseOffsets], {{0.0, 0.0}, {0.0, 0.0}}]
  ];
  phaseEigs = Sort[Chop[Quiet @ Check[Eigenvalues[phaseCov], {0.0, 0.0}], 10^-12]];
  phaseIsotropy = If[
    Length[phaseEigs] < 2 || safeReal[phaseEigs[[-1]], 0.0] <= 10^-12,
    0.0,
    Clamp01[safeReal[Max[0.0, phaseEigs[[1]]]/phaseEigs[[-1]], 0.0]]
  ];
  meanRadius = If[Length[phaseR] == 0, 0.0, safeReal[Mean[phaseR], 0.0]];
  phaseRingTightness = If[
    Length[phaseR] < 4 || meanRadius <= 10^-12,
    0.0,
    Clamp01[1.0 - safeReal[StandardDeviation[phaseR], 0.0]/(meanRadius + 10^-9)]
  ];
  phaseRadiusSpan = If[
    Length[phaseR] < 4,
    0.0,
    Clamp01[safeReal[Quantile[phaseR, 0.90] - Quantile[phaseR, 0.10], 0.0]/0.55]
  ];
  centerAnchor = Clamp01[safeReal[1.0 - meanRadius/0.60, 0.0]];

  dy = Differences[y];
  ddy = Differences[dy];
  slopeEntropy = If[Length[dy] < 2, 0.0, safeReal[Entropy01 @ Counts[Round[dy, 0.05]], 0.0]];
  inflections = If[
    Length[ddy] < 2,
    0,
    Count[Partition[Sign[ddy], 2, 1], {a_, b_} /; a*b == -1]
  ];
  curvatureVolatility = If[Length[ddy] < 2, 0.0, safeReal[StandardDeviation[ddy], 0.0]];

  peakCount = Min[6, n];
  peakIdx = Sort[Ordering[y, -peakCount]];
  peakGaps = Differences[peakIdx];
  peakGapCV = If[
    Length[peakGaps] < 2 || Mean[peakGaps] <= 10^-12,
    1.0,
    safeReal[StandardDeviation[peakGaps], 0.0]/(safeReal[Mean[peakGaps], 0.0] + 10^-9)
  ];
  peakYSpread = If[Length[peakIdx] < 2, 0.0, safeReal[StandardDeviation[y[[peakIdx]]], 0.0]];

  thirdBins = Clip[1 + Floor[3*x - 10^-9], {1, 3}];
  thirdFractions = N[Lookup[Counts[thirdBins], Range[3], 0]]/n;
  thirdBalance = If[
    Mean[thirdFractions] <= 10^-12,
    0.0,
    Clamp01[
      1.0 - safeReal[StandardDeviation[thirdFractions], 0.0]/(safeReal[Mean[thirdFractions], 0.0] + 10^-9)
    ]
  ];

  apexIndex = First @ Ordering[y, -1];
  apexX = safeReal[x[[apexIndex]], 0.5];
  leftPart = If[apexIndex > 1, Differences[y[[1 ;; apexIndex]]], {}];
  rightPart = If[apexIndex < n, Differences[y[[apexIndex ;; n]]], {}];
  leftRisingRatio = If[
    Length[leftPart] == 0,
    0.0,
    safeReal[Count[leftPart, _?(# >= 0 &)]/Length[leftPart], 0.0]
  ];
  rightFallingRatio = If[
    Length[rightPart] == 0,
    0.0,
    safeReal[Count[rightPart, _?(# <= 0 &)]/Length[rightPart], 0.0]
  ];

  diag1 = safeReal[Abs @ Quiet @ Check[Correlation[x, y], 0.0], 0.0];
  diag2 = safeReal[Abs @ Quiet @ Check[Correlation[x, 1.0 - y], 0.0], 0.0];
  diagonalAlignment = Clamp01[Max[diag1, diag2]];

  crossMass = safeReal[(Total[colMass[[centerCols]]] + Total[rowMass[[centerRows]]] - centerMassRaw)]/total;
  leftRightBalance = Clamp01[safeReal[1.0 - Abs[leftMass - rightMass]/total, 0.0]];
  topBottomBalance = Clamp01[safeReal[1.0 - Abs[topMass - bottomMass]/total, 0.0]];
  leftRightImbalance = Clamp01[safeReal[Abs[leftMass - rightMass]/total, 0.0]];
  minorSideFraction = safeReal[Min[leftMass, rightMass]/total, 0.0];

  <|
    "LeftRightBalance" -> leftRightBalance,
    "TopBottomBalance" -> topBottomBalance,
    "LeftRightImbalance" -> leftRightImbalance,
    "MinorSideFraction" -> minorSideFraction,
    "CenterMassFraction" -> centerMass,
    "CenterRowMassFraction" -> centerRowMass,
    "CenterColumnMassFraction" -> centerColMass,
    "EdgeMassFraction" -> Clamp01[edgeMass/total],
    "LEdgeMassFraction" -> Clamp01[lEdgeMass],
    "TopMassFraction" -> Clamp01[topMass/total],
    "DominantCellFraction" -> Clamp01[N[Max[Flatten[matrix]]]/total],
    "OccupiedFraction" -> Clamp01[occupiedFraction],
    "RowEntropy" -> rowEntropy,
    "ColumnEntropy" -> columnEntropy,
    "VerticalEntropy" -> verticalEntropy,
    "SlopeEntropy" -> slopeEntropy,
    "InflectionCount" -> inflections,
    "CurvatureVolatility" -> curvatureVolatility,
    "PeakGapCV" -> peakGapCV,
    "PeakYSpread" -> peakYSpread,
    "ThirdBalance" -> thirdBalance,
    "ApexX" -> apexX,
    "LeftRisingRatio" -> Clamp01[leftRisingRatio],
    "RightFallingRatio" -> Clamp01[rightFallingRatio],
    "DiagonalAlignment" -> diagonalAlignment,
    "CrossMassFraction" -> Clamp01[crossMass],
    "PhaseAngleEntropy" -> phaseAngleEntropy,
    "PhaseIsotropy" -> phaseIsotropy,
    "PhaseRingTightness" -> phaseRingTightness,
    "PhaseRadiusSpan" -> phaseRadiusSpan,
    "CenterAnchor" -> centerAnchor
  |>
];

CompositionGuideScores[geometry_Association] := Module[
  {g, near, steelyard, balancedScales, oCircular, sCurve, pyramid, cross, radiating, lRect,
   suspendedSteelyard, treeSpots, groupMass, diagonal, tunnel},
  g = geometry;
  near[value_, target_, width_] := Clamp01[1.0 - Abs[N[value] - target]/Max[10^-9, width]];

  steelyard = Clamp01[
    0.42*near[g["LeftRightImbalance"], 0.35, 0.35] +
    0.33*Clamp01[g["MinorSideFraction"]/0.35] +
    0.25*near[g["CenterMassFraction"], 0.12, 0.12]
  ];
  balancedScales = Clamp01[0.70*g["LeftRightBalance"] + 0.30*g["VerticalEntropy"]];
  oCircular = Clamp01[
    0.45*g["PhaseIsotropy"] + 0.30*g["PhaseRingTightness"] + 0.25*g["PhaseAngleEntropy"]
  ];
  sCurve = Clamp01[
    0.58*Exp[-((N[g["InflectionCount"]] - 3.0)^2)/6.0] +
    0.42*Exp[-6.0*g["CurvatureVolatility"]]
  ];
  pyramid = Clamp01[
    0.34*Max[
      Exp[-((g["ApexX"] - 0.33)^2)/0.03],
      Exp[-((g["ApexX"] - 0.67)^2)/0.03]
    ] +
    0.33*g["LeftRisingRatio"] +
    0.33*g["RightFallingRatio"]
  ];
  cross = Clamp01[0.65*g["CrossMassFraction"] + 0.35*(1.0 - g["CenterMassFraction"])];
  radiating = Clamp01[
    0.50*g["PhaseAngleEntropy"] + 0.28*g["PhaseRadiusSpan"] + 0.22*g["CenterAnchor"]
  ];
  lRect = Clamp01[0.58*g["LEdgeMassFraction"] + 0.42*(1.0 - g["CenterMassFraction"])];
  suspendedSteelyard = Clamp01[
    0.52*steelyard + 0.28*g["TopMassFraction"] + 0.20*g["CenterRowMassFraction"]
  ];
  treeSpots = Clamp01[
    0.62*Exp[-((g["PeakGapCV"] - 0.55)^2)/0.22] +
    0.38*near[g["DominantCellFraction"], 0.18, 0.18]
  ];
  groupMass = Clamp01[0.72*g["DominantCellFraction"] + 0.28*(1.0 - g["OccupiedFraction"])];
  diagonal = g["DiagonalAlignment"];
  tunnel = Clamp01[0.66*g["EdgeMassFraction"] + 0.34*(1.0 - g["CenterMassFraction"])];

  <|
    "Steelyard" -> steelyard,
    "BalancedScales" -> balancedScales,
    "OCircular" -> oCircular,
    "SCompoundCurve" -> sCurve,
    "PyramidTriangle" -> pyramid,
    "Cross" -> cross,
    "RadiatingLines" -> radiating,
    "LRectangular" -> lRect,
    "SuspendedSteelyard" -> suspendedSteelyard,
    "TreeSpots" -> treeSpots,
    "GroupMass" -> groupMass,
    "DiagonalLine" -> diagonal,
    "Tunnel" -> tunnel
  |>
];

CompositionGuideScores[data_List] := CompositionGuideScores[SequenceCompositionGeometry[data]];

CompositionAvoidPenalties[geometry_Association] := Module[
  {g, equalMasses, canvasHalved, equalSpacing, parallelLines, linesNearEdge,
   treesOnLine, centeredObjects, centeredHorizon, scatteredCenteredHorizon,
   threeEqualDivisions, crowdedDesign},
  g = geometry;

  equalMasses = Max[g["LeftRightBalance"], g["TopBottomBalance"]];
  canvasHalved = Clamp01[
    Max[
      g["LeftRightBalance"]*(1.0 - g["CenterColumnMassFraction"]),
      g["TopBottomBalance"]*(1.0 - g["CenterRowMassFraction"])
    ]
  ];
  equalSpacing = Clamp01[1.0 - Clip[g["PeakGapCV"]/0.90, {0.0, 1.0}]];
  parallelLines = Clamp01[1.0 - g["SlopeEntropy"]];
  linesNearEdge = g["EdgeMassFraction"];
  treesOnLine = Clamp01[1.0 - Clip[g["PeakYSpread"]/0.18, {0.0, 1.0}]];
  centeredObjects = g["CenterMassFraction"];
  centeredHorizon = g["CenterRowMassFraction"];
  scatteredCenteredHorizon = Clamp01[
    g["CenterRowMassFraction"]*(1.0 - g["DominantCellFraction"])*g["OccupiedFraction"]
  ];
  threeEqualDivisions = g["ThirdBalance"];
  crowdedDesign = Clamp01[
    g["OccupiedFraction"]*(0.5*g["RowEntropy"] + 0.5*g["ColumnEntropy"])
  ];

  <|
    "CanvasHalved" -> canvasHalved,
    "EqualSpacingOfMasses" -> equalSpacing,
    "TooManyParallelLines" -> parallelLines,
    "LinesTooNearEdge" -> linesNearEdge,
    "TreesOnALine" -> treesOnLine,
    "CenteredObjects" -> centeredObjects,
    "CenteredHorizon" -> centeredHorizon,
    "ScatteredObjectsCenteredHorizon" -> scatteredCenteredHorizon,
    "ThreeEqualDivisions" -> threeEqualDivisions,
    "EqualMasses" -> equalMasses,
    "CrowdedDesign" -> crowdedDesign
  |>
];

CompositionAvoidPenalties[data_List] := CompositionAvoidPenalties[SequenceCompositionGeometry[data]];

CompositionPowerProfile[data_List] := Module[
  {geometry, guides, penalties, guideMean, avoidMean, compositionPower},
  geometry = SequenceCompositionGeometry[data];
  guides = CompositionGuideScores[geometry];
  penalties = CompositionAvoidPenalties[geometry];
  guideMean = If[Length[guides] == 0, 0.0, Quiet @ Check[N[Mean[Values[guides]]], 0.0]];
  avoidMean = If[Length[penalties] == 0, 0.0, Quiet @ Check[N[Mean[Values[penalties]]], 0.0]];
  If[!NumericQ[guideMean] || guideMean === Indeterminate, guideMean = 0.0];
  If[!NumericQ[avoidMean] || avoidMean === Indeterminate, avoidMean = 1.0];
  compositionPower = Clamp01[0.80*guideMean + 0.20*(1.0 - avoidMean)];
  <|
    "Geometry" -> geometry,
    "Guides" -> guides,
    "AvoidPenalties" -> penalties,
    "GuideMean" -> guideMean,
    "AvoidMean" -> avoidMean,
    "CompositionPower" -> compositionPower
  |>
];

BeautyProfile[data_List, modulus : (_Integer?Positive) : 12] := Module[
  {
    compressibility, deltaEntropy, growthDrama, residueStructure, novelty,
    structuralBeauty, composition
  },
  compressibility = CompressibilityScore[data];
  deltaEntropy = DeltaSignEntropyScore[data];
  growthDrama = GrowthDramaScore[data];
  residueStructure = ResidueStructureScore[data, modulus];
  novelty = NoveltyScore[data];
  composition = CompositionPowerProfile[data];
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
    "CompositionPower" -> Lookup[composition, "CompositionPower", 0.0],
    "CompositionGuideMean" -> Lookup[composition, "GuideMean", 0.0],
    "CompositionAvoidPenalty" -> Lookup[composition, "AvoidMean", 0.0],
    "CompositionGuides" -> Lookup[composition, "Guides", <||>],
    "CompositionAvoid" -> Lookup[composition, "AvoidPenalties", <||>],
    "CompositionGeometry" -> Lookup[composition, "Geometry", <||>],
    "CoagulationScore" -> 0.0,
    "CoagulationMode" -> "none",
    "CoagulationScores" -> <||>,
    "BeautyIndex" -> Clamp01[
      0.82*structuralBeauty + 0.18*Lookup[composition, "CompositionPower", 0.0]
    ]
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

CoagulationBlendImage[id_String, visuals_Association] := Module[
  {priority, selectedKeys, imgs, n, palette, alphas, canvas},
  priority = {
    "difference", "phase", "recurrence", "mod-spiral",
    "digitgraph", "residue", "line", "digits", "mod-circle", "arcs", "runs"
  };
  selectedKeys = Take[Select[priority, KeyExistsQ[visuals, #] &], UpTo[7]];
  imgs = DeleteCases[RasterizeGraphicImage[visuals[#], 820] & /@ selectedKeys, $Failed];
  n = Length[imgs];
  If[n == 0, Return[CoagulationCompositeImage[id, visuals]]];
  imgs = ImageResize[ColorConvert[#, "RGB"], {820, 820}] & /@ imgs;
  palette = ColorData["DarkRainbow"] /@ Subdivide[0.08, 0.92, Max[1, n - 1]];
  alphas = If[n == 1, {0.42}, Subdivide[0.16, 0.36, n - 1]];
  canvas = Image[
    ConstantArray[{0.035, 0.035, 0.040}, {820, 820}],
    "Real",
    ColorSpace -> "RGB"
  ];
  Do[
    Module[{gray, detail, edges, mix, feature, layer},
      gray = ColorConvert[imgs[[i]], "Grayscale"];
      detail = ImageDifference[gray, GaussianFilter[gray, 2.8]];
      edges = EdgeDetect[gray, 1.8];
      mix = ImageAdd[
        ImageMultiply[detail, 0.62],
        ImageMultiply[edges, 0.88]
      ];
      feature = Image[Rescale[ImageData[mix]], "Real"];
      layer = Colorize[
        feature,
        ColorFunction -> (Blend[{RGBColor[0.03, 0.03, 0.04], palette[[i]]}, #] &)
      ];
      canvas = ImageCompose[canvas, SetAlphaChannel[layer, alphas[[i]]]];
    ],
    {i, 1, n}
  ];
  ImageAdjust[canvas]
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

IntegrateCoagulationIntoProfile[
  profile_Association,
  coagScore_,
  coagMode_String : "single",
  coagScores_Association : <||>
] := Module[
  {structural, composition, beauty},
  structural = Lookup[profile, "StructuralBeauty", 0.0];
  composition = Lookup[profile, "CompositionPower", 0.0];
  beauty = Clamp01[0.52*coagScore + 0.30*structural + 0.18*composition];
  Join[
    profile,
    <|
      "CoagulationScore" -> coagScore,
      "CoagulationMode" -> coagMode,
      "CoagulationScores" -> coagScores,
      "BeautyIndex" -> beauty
    |>
  ]
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
        MemberQ[
          {"coagulation", "coagulation-tile", "coagulation-blend", "mod-spiral", "mod-circle", "recurrence", "digitgraph", "arcs"},
          name
        ],
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
            " | CoagulationMode=" <> ToString[Lookup[record["Profile"], "CoagulationMode", "n/a"]] <>
            " | StructuralBeauty=" <> FormatMetric[record["Profile"]["StructuralBeauty"]] <>
            " | CompositionPower=" <> FormatMetric[Lookup[record["Profile"], "CompositionPower", 0.0]] <>
            " | CompositionGuideMean=" <> FormatMetric[Lookup[record["Profile"], "CompositionGuideMean", 0.0]] <>
            " | CompositionAvoidPenalty=" <> FormatMetric[Lookup[record["Profile"], "CompositionAvoidPenalty", 0.0]] <>
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
          oeis, atlas, atlasFile, animationFiles,
          coagulationTileImage, coagulationBlendImage,
          coagulationScores, coagulationMode, coagulationScore
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
        coagulationTileImage = CoagulationCompositeImage[id, visuals];
        coagulationBlendImage = CoagulationBlendImage[id, visuals];
        AssociateTo[
          visuals,
          <|
            "coagulation-tile" -> coagulationTileImage,
            "coagulation-blend" -> coagulationBlendImage
          |>
        ];
        coagulationScores = <|
          "tile" -> CoagulationScore[coagulationTileImage, visuals],
          "blend" -> CoagulationScore[coagulationBlendImage, visuals]
        |>;
        coagulationMode = First @ First @ ReverseSortBy[Normal[coagulationScores], Last];
        coagulationScore = Lookup[coagulationScores, coagulationMode, 0.0];
        AssociateTo[visuals, "coagulation" -> visuals["coagulation-" <> coagulationMode]];
        profile = IntegrateCoagulationIntoProfile[profile, coagulationScore, coagulationMode, coagulationScores];

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
