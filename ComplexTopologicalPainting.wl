(* ============================================================================ *)
(* COMPLEX TOPOLOGICAL PAINTING                                                *)
(* Analytic Continuation → Image Convolutions → Neural Network → Weight Art    *)
(* ============================================================================ *)
(* A mixed-media computational artwork in four movements.                      *)
(* Russell — this script is designed for Mathematica 13+.                      *)
(* Run each section sequentially, or evaluate the entire notebook.             *)
(* ============================================================================ *)

(* -------------------------------------------------------------------------- *)
(* MOVEMENT I: THE COMPLEX PLANE AS CANVAS                                    *)
(* -------------------------------------------------------------------------- *)
(* We compose several analytically continued functions to create a             *)
(* topological painting. The Riemann zeta function, Gamma function,            *)
(* and Weierstrass elliptic function each carry their own singularity          *)
(* structure — poles, branch cuts, essential singularities — and when          *)
(* composed, they create interference patterns that are genuinely surprising.  *)
(* -------------------------------------------------------------------------- *)

Print["═══════════════════════════════════════════════════"];
Print["  MOVEMENT I: Analytic Continuation Painting"];
Print["═══════════════════════════════════════════════════"];

(* --- Painting 1: The Zeta-Gamma Interference Field --- *)
(* Domain coloring of ζ(Γ(z)) — the zeta function composed with Gamma.       *)
(* Γ has poles at non-positive integers; ζ has a pole at 1 and trivial zeros  *)
(* at negative even integers. Their composition creates a fractal-like        *)
(* singularity landscape through analytic continuation.                        *)

zetaGammaPainting = ComplexPlot[
  Zeta[Gamma[z]],
  {z, -4 - 4 I, 4 + 4 I},
  PlotPoints -> 300,
  ColorFunction -> "CyclicLogAbs",
  PlotRange -> All,
  ImageSize -> 600,
  PlotLabel -> Style["ζ(Γ(z)) — Zeta-Gamma Interference", 14, Bold,
    FontFamily -> "Palatino"],
  Epilog -> {
    Opacity[0.3], White,
    Text[Style["poles cascade\nthrough analytic\ncontinuation",
      Italic, 10, White], {-2, 3}]
  }
];

Print["  ✓ Zeta-Gamma interference field complete"];

(* --- Painting 2: Modular Dream — the Dedekind Eta Quotient --- *)
(* The Dedekind eta function η(τ) is a modular form of weight 1/2.           *)
(* We visualize η(z)^24 / η(2z)^12 which has beautiful modular symmetry.    *)
(* This lives naturally on the upper half-plane.                               *)

modularDream = ComplexPlot[
  DedekindEta[z]^24 / (DedekindEta[2 z]^12 + 10^-10),
  {z, -1 + 0.01 I, 1 + 2 I},
  PlotPoints -> 400,
  ColorFunction -> "TemperatureMap",
  ImageSize -> 600,
  PlotLabel -> Style["η(z)²⁴ / η(2z)¹² — Modular Dream", 14, Bold,
    FontFamily -> "Palatino"],
  PlotRange -> All
];

Print["  ✓ Modular Dream complete"];

(* --- Painting 3: The Riemann Surface Projection --- *)
(* A composition: Zeta[z^2 + z*Conjugate[z]] won't work in ComplexPlot      *)
(* since it needs analytic functions. Instead, let's create something         *)
(* topologically rich: the phase portrait of z ↦ ζ(z) * WeierstrassP[z, {2,3}] *)

weierstrassZeta = ComplexPlot[
  Zeta[z] * WeierstrassPPrime[z, {2, -1}],
  {z, -4 - 4 I, 4 + 4 I},
  PlotPoints -> 300,
  ColorFunction -> "DarkRainbow",
  ImageSize -> 600,
  PlotLabel -> Style["ζ(z) · ℘'(z; 2, -1) — Arithmetic Topology", 14, Bold,
    FontFamily -> "Palatino"]
];

Print["  ✓ Arithmetic Topology painting complete"];

(* --- Painting 4: Surprise — The Polylogarithm Spiral --- *)
(* Li_s(z) for complex s creates stunning spiral patterns.                    *)
(* We use s = 1/2 + 3i, giving the polylogarithm a complex order.           *)
(* This is genuinely surprising: a fractional-imaginary order polylogarithm. *)

polylogSpiral = ComplexPlot[
  PolyLog[1/2 + 3 I, z],
  {z, -3 - 3 I, 3 + 3 I},
  PlotPoints -> 350,
  ColorFunction -> "SunsetColors",
  ImageSize -> 600,
  PlotLabel -> Style["Li_{1/2+3i}(z) — Polylogarithmic Spiral", 14, Bold,
    FontFamily -> "Palatino"]
];

Print["  ✓ Polylogarithmic spiral complete"];

(* --- Painting 5: The Grand Composition --- *)
(* Layer all four functions into a single domain coloring.                    *)
(* f(z) = ζ(z) · Li_{1/2+3i}(z) / (Γ(z) + η(z/4)^6)                      *)
(* This creates an extraordinary singularity landscape.                       *)

grandComposition = ComplexPlot[
  Zeta[z] * PolyLog[1/2 + 3 I, z] /
    (Gamma[z] + DedekindEta[z/4 + I]^6 + 10^-12),
  {z, -3 - 3 I, 3 + 3 I},
  PlotPoints -> 350,
  ColorFunction -> "AvocadoColors",
  ImageSize -> 800,
  PlotLabel -> Style[
    "ζ(z)·Li_{1/2+3i}(z) / (Γ(z) + η(z/4+i)⁶)\nThe Grand Composition",
    16, Bold, FontFamily -> "Palatino"],
  PlotRange -> All
];

Print["  ✓ Grand Composition complete\n"];

(* Assemble the gallery *)
paintingGallery = GraphicsGrid[{
  {zetaGammaPainting, modularDream},
  {weierstrassZeta, polylogSpiral}
}, ImageSize -> 1200, Spacings -> {10, 10},
  PlotLabel -> Style["Complex Topological Paintings", 20, Bold,
    FontFamily -> "Palatino"]
];

(* Export high-res versions *)
Export["painting_gallery.png", paintingGallery, ImageResolution -> 200];
Export["grand_composition.png", grandComposition, ImageResolution -> 300];

Print["  Gallery and Grand Composition exported as PNG"];


(* -------------------------------------------------------------------------- *)
(* MOVEMENT II: IMAGE FILTERS & CONVOLUTIONS                                  *)
(* -------------------------------------------------------------------------- *)
(* Now we treat our complex paintings as images and apply a battery of         *)
(* filters — both standard and custom convolution kernels. The idea:          *)
(* analytic continuation created the topology; convolution reveals its         *)
(* hidden structure, like staining a histological slide.                       *)
(* -------------------------------------------------------------------------- *)

Print["\n═══════════════════════════════════════════════════"];
Print["  MOVEMENT II: Image Filters & Convolutions"];
Print["═══════════════════════════════════════════════════"];

(* Convert our paintings to images for filtering *)
img1 = Rasterize[zetaGammaPainting, ImageSize -> 512, ImageResolution -> 150];
img2 = Rasterize[modularDream, ImageSize -> 512, ImageResolution -> 150];
img3 = Rasterize[grandComposition, ImageSize -> 512, ImageResolution -> 150];

(* --- Standard Filters --- *)

(* Gaussian blur at multiple scales — reveals large-scale topology *)
gaussianMultiscale = Table[
  GaussianFilter[img3, r],
  {r, {1, 3, 8, 20}}
];

(* Laplacian of Gaussian — edge detection that finds singularity boundaries *)
logFiltered = LaplacianGaussianFilter[img3, 3];

(* Derivative filters — directional gradients *)
gradX = DerivativeFilter[img3, {1, 0}];
gradY = DerivativeFilter[img3, {0, 1}];
gradMagnitude = ImageAdd[ImageMultiply[gradX, gradX], ImageMultiply[gradY, gradY]];

(* Edge detection *)
edgesImg = EdgeDetect[img3, 2, 0.1];

Print["  ✓ Standard filters applied"];

(* --- Custom Convolution Kernels --- *)

(* Emboss kernel — gives the painting a bas-relief sculptural quality *)
embossKernel = {{-2, -1, 0}, {-1, 1, 1}, {0, 1, 2}};
embossed = ImageConvolve[img3, embossKernel];

(* Sharpen kernel — enhances singularity detail *)
sharpenKernel = {{0, -1, 0}, {-1, 5, -1}, {0, -1, 0}};
sharpened = ImageConvolve[img3, sharpenKernel];

(* Custom "Singularity Detector" — a difference of Gaussians *)
(* Both matrices must be the same size: use {radius, sigma} form *)
dogKernel = GaussianMatrix[{5, 2}] - GaussianMatrix[{5, 5}];
singularityDetected = ImageConvolve[img3, dogKernel];

(* Gabor filter bank — detects oriented features at multiple angles *)
gaborBank = Table[
  GaborFilter[img3, 8, {Cos[θ], Sin[θ]}],
  {θ, 0, π, π/6}
];

(* Morphological gradient — topological boundary extraction *)
morphGrad = ImageDifference[Dilation[img3, 2], Erosion[img3, 2]];

(* Artistic: Total Variation denoising then re-sharpening *)
tvDenoised = TotalVariationFilter[img3, 0.3];
artisticFilter = ImageConvolve[tvDenoised, sharpenKernel];

Print["  ✓ Custom convolution kernels applied"];

(* --- Frequency Domain Filtering --- *)

(* Fourier transform, visualize spectrum, apply bandpass *)
imgGray = ColorConvert[img3, "Grayscale"];
imgData = ImageData[imgGray];
fourierData = Fourier[imgData];
powerSpectrum = Log[1 + Abs[fourierData]];

(* Visualize the power spectrum — itself a beautiful image *)
spectrumImage = Image[
  Rescale[RotateLeft[powerSpectrum, Floor[Dimensions[powerSpectrum]/2]]],
  ImageSize -> 512
];

(* High-pass filter in frequency domain — reveals fine singularity structure *)
{rows, cols} = Dimensions[imgData];
highPassMask = Table[
  If[Norm[{r - rows/2, c - cols/2}] > 20, 1.0, 0.0],
  {r, rows}, {c, cols}
];
shiftedFourier = RotateLeft[fourierData, Floor[{rows, cols}/2]];
highPassFiltered = InverseFourier[
  RotateRight[shiftedFourier * highPassMask, Floor[{rows, cols}/2]]
];
highPassImage = Image[Rescale[Abs[highPassFiltered]], ImageSize -> 512];

Print["  ✓ Frequency domain analysis complete"];

(* --- Assemble the Filter Gallery --- *)
filterGallery = GraphicsGrid[{
  {Labeled[embossed, "Emboss", Top],
   Labeled[sharpened, "Sharpen", Top],
   Labeled[singularityDetected, "DoG Singularity", Top]},
  {Labeled[edgesImg, "Edge Detect", Top],
   Labeled[morphGrad, "Morphological Gradient", Top],
   Labeled[spectrumImage, "Fourier Spectrum", Top]},
  {Labeled[logFiltered, "LoG Filter", Top],
   Labeled[artisticFilter, "TV + Sharpen", Top],
   Labeled[highPassImage, "High-Pass", Top]}
}, ImageSize -> 1400, Spacings -> {5, 5},
  PlotLabel -> Style["Convolution Gallery — Revealing Hidden Topology",
    18, Bold, FontFamily -> "Palatino"]
];

Export["filter_gallery.png", filterGallery, ImageResolution -> 200];

(* Gabor orientation gallery *)
gaborGallery = GraphicsRow[
  MapIndexed[
    Labeled[#1, ToString[Round[N[(#2[[1]] - 1) π/6 * 180/π]]] <> "°", Top] &,
    gaborBank
  ],
  ImageSize -> 1400,
  PlotLabel -> Style["Gabor Filter Bank — Oriented Feature Detection",
    16, Bold, FontFamily -> "Palatino"]
];

Export["gabor_gallery.png", gaborGallery, ImageResolution -> 200];

Print["  Filter gallery and Gabor gallery exported\n"];


(* -------------------------------------------------------------------------- *)
(* MOVEMENT III: NEURAL NETWORK ARCHITECTURE & TRAINING                       *)
(* -------------------------------------------------------------------------- *)
(* We design a small convolutional autoencoder that learns to compress         *)
(* and reconstruct our complex paintings. The latent space of this network    *)
(* becomes a learned topological summary of our analytic continuations.       *)
(* We also train a classifier to distinguish which painting a patch came from.*)
(* -------------------------------------------------------------------------- *)

Print["═══════════════════════════════════════════════════"];
Print["  MOVEMENT III: Neural Network Training"];
Print["═══════════════════════════════════════════════════"];

(* --- Prepare Training Data --- *)
(* Extract patches from each painting and its filtered versions *)

(* Resize all source images to uniform 256x256 *)
(* Validate each image first — filter failures produce non-Image results *)
rawSources = {img1, img2, img3, embossed, sharpened, singularityDetected, artisticFilter};
patchLabels = {"ZetaGamma", "Modular", "Grand",
               "Embossed", "Sharpened", "DoG", "Artistic"};

(* Keep only valid images *)
validMask = ImageQ /@ rawSources;
sourceImages = Pick[rawSources, validMask];
validLabels = Pick[patchLabels, validMask];
sourceImages = ImageResize[#, {256, 256}] & /@ sourceImages;

Print["  Valid source images: " <> ToString[Length[sourceImages]] <>
      " / " <> ToString[Length[rawSources]]];

(* Extract 32x32 patches with stride 32 for training *)
extractPatches[img_?ImageQ, patchSize_: 32, stride_: 32] := Module[
  {data, rows, cols, patches = {}},
  data = ImageData[ImageResize[img, {256, 256}]];
  {rows, cols} = Most[Dimensions[data]];
  Do[
    AppendTo[patches,
      Image[data[[r ;; r + patchSize - 1, c ;; c + patchSize - 1]]]
    ],
    {r, 1, rows - patchSize + 1, stride},
    {c, 1, cols - patchSize + 1, stride}
  ];
  patches
];

(* Generate labeled training data *)
trainingPatches = {};
trainingLabels = {};

Do[
  patches = extractPatches[sourceImages[[i]], 32, 32];
  trainingPatches = Join[trainingPatches, patches];
  trainingLabels = Join[trainingLabels,
    ConstantArray[validLabels[[i]], Length[patches]]
  ],
  {i, Length[sourceImages]}
];

Print["  Extracted " <> ToString[Length[trainingPatches]] <> " training patches"];

(* Shuffle the data *)
SeedRandom[42];
shuffleIdx = RandomSample[Range[Length[trainingPatches]]];
trainingPatches = trainingPatches[[shuffleIdx]];
trainingLabels = trainingLabels[[shuffleIdx]];

(* Create training/validation split *)
nTrain = Floor[0.8 * Length[trainingPatches]];
trainData = Thread[trainingPatches[[;; nTrain]] -> trainingLabels[[;; nTrain]]];
valData = Thread[trainingPatches[[nTrain + 1 ;;]] -> trainingLabels[[nTrain + 1 ;;]]];

Print["  Training: " <> ToString[Length[trainData]] <>
      " | Validation: " <> ToString[Length[valData]]];

nClasses = Length[validLabels];

(* --- Architecture A: Convolutional Classifier --- *)
(* A small but expressive ConvNet that learns to identify the                 *)
(* topological signature of each painting/filter combination.                  *)

classifier = NetChain[{
  (* Block 1: Initial feature extraction *)
  ConvolutionLayer[16, {5, 5}, "PaddingSize" -> 2],
  BatchNormalizationLayer[],
  ElementwiseLayer[Ramp],  (* ReLU *)
  PoolingLayer[{2, 2}, "Stride" -> 2],

  (* Block 2: Deeper features *)
  ConvolutionLayer[32, {3, 3}, "PaddingSize" -> 1],
  BatchNormalizationLayer[],
  ElementwiseLayer[Ramp],
  PoolingLayer[{2, 2}, "Stride" -> 2],

  (* Block 3: Abstract representations *)
  ConvolutionLayer[64, {3, 3}, "PaddingSize" -> 1],
  BatchNormalizationLayer[],
  ElementwiseLayer[Ramp],
  PoolingLayer[{2, 2}, "Stride" -> 2],

  (* Block 4: Highest level features *)
  ConvolutionLayer[32, {3, 3}, "PaddingSize" -> 1],
  ElementwiseLayer[Tanh],

  (* Classification head *)
  FlattenLayer[],
  LinearLayer[64],
  ElementwiseLayer[Ramp],
  DropoutLayer[0.3],
  LinearLayer[nClasses],
  SoftmaxLayer[]
},
  "Input" -> NetEncoder[{"Image", {32, 32}, ColorSpace -> "RGB"}],
  "Output" -> NetDecoder[{"Class", validLabels}]
];

Print["  Classifier architecture defined"];
Print["    Parameters: " <> ToString[NetInformation[classifier, "ArraysCount"]]];

(* --- Architecture B: Convolutional Autoencoder --- *)
(* Learns a compressed representation of the paintings' topology.             *)
(* The bottleneck forces the network to find essential structure.              *)
(* NOTE: No NetDecoder on output — we train against raw 3x32x32 tensors.    *)

encoder = NetChain[{
  ConvolutionLayer[16, {3, 3}, "PaddingSize" -> 1],
  ElementwiseLayer[Ramp],
  PoolingLayer[{2, 2}, "Stride" -> 2],          (* 32 -> 16 *)
  ConvolutionLayer[32, {3, 3}, "PaddingSize" -> 1],
  ElementwiseLayer[Ramp],
  PoolingLayer[{2, 2}, "Stride" -> 2],          (* 16 -> 8 *)
  ConvolutionLayer[8, {3, 3}, "PaddingSize" -> 1],  (* bottleneck: 8 channels *)
  ElementwiseLayer[Tanh]
},
  "Input" -> NetEncoder[{"Image", {32, 32}, ColorSpace -> "RGB"}]
];

decoder = NetChain[{
  DeconvolutionLayer[32, {3, 3}, "PaddingSize" -> 1],
  ElementwiseLayer[Ramp],
  ResizeLayer[{16, 16}],                        (* 8 -> 16 *)
  DeconvolutionLayer[16, {3, 3}, "PaddingSize" -> 1],
  ElementwiseLayer[Ramp],
  ResizeLayer[{32, 32}],                        (* 16 -> 32 *)
  DeconvolutionLayer[3, {3, 3}, "PaddingSize" -> 1],
  ElementwiseLayer[LogisticSigmoid]             (* output in [0,1] *)
}];

(* No NetDecoder — output is raw 3x32x32 tensor *)
autoencoder = NetChain[{encoder, decoder},
  "Input" -> NetEncoder[{"Image", {32, 32}, ColorSpace -> "RGB"}]
];

Print["  Autoencoder architecture defined"];

(* --- Train the Classifier --- *)
(* NOTE: Do NOT specify LossFunction explicitly.                              *)
(* NetTrain automatically uses CrossEntropyLossLayer when it sees             *)
(* a NetDecoder[{"Class", ...}] on the output port. Specifying                *)
(* CrossEntropyLossLayer["Index"] manually conflicts with string labels.      *)
Print["\n  Training classifier..."];

trainedClassifier = NetTrain[
  classifier,
  trainData,
  ValidationSet -> valData,
  MaxTrainingRounds -> 25,
  BatchSize -> 32,
  TargetDevice -> "CPU",
  TrainingProgressReporting -> "Print"
];

(* Evaluate *)
If[Head[trainedClassifier] === NetChain,
  classifierAccuracy = ClassifierMeasurements[
    trainedClassifier, valData, "Accuracy"
  ];
  Print["  Classifier trained — Validation accuracy: " <>
        ToString[NumberForm[classifierAccuracy * 100, 4]] <> "%"];
  confusionPlot = ClassifierMeasurements[
    trainedClassifier, valData, "ConfusionMatrixPlot"
  ];,
  (* else *)
  Print["  WARNING: Classifier training returned $Failed"];
  classifierAccuracy = 0;
  confusionPlot = Graphics[Text["Training Failed"]];
];

(* --- Train the Autoencoder --- *)
(* Training targets are raw 3x32x32 tensors (channels-first, non-interleaved) *)
Print["\n  Training autoencoder..."];

makeTarget[img_?ImageQ] :=
  ImageData[ImageResize[img, {32, 32}], Interleaving -> False];

autoencoderTrainData = Table[
  trainingPatches[[i]] -> makeTarget[trainingPatches[[i]]],
  {i, nTrain}
];

trainedAutoencoder = NetTrain[
  autoencoder,
  autoencoderTrainData,
  MaxTrainingRounds -> 20,
  BatchSize -> 32,
  LossFunction -> MeanSquaredLossLayer[],
  TargetDevice -> "CPU",
  TrainingProgressReporting -> "Print"
];

If[Head[trainedAutoencoder] === NetChain,
  Print["  Autoencoder trained successfully\n"];

  (* Show some reconstructions *)
  SeedRandom[7];
  samplePatches = RandomSample[trainingPatches, 6];
  rawOutputs = trainedAutoencoder /@ samplePatches;
  (* Convert 3x32x32 tensor back to Image: transpose to 32x32x3 *)
  reconstructedImages = Image[Clip[Transpose[Normal[#], {2, 3, 1}], {0, 1}]] & /@ rawOutputs;

  reconstructionComparison = GraphicsGrid[{
    ImageResize[#, 80] & /@ samplePatches,
    ImageResize[#, 80] & /@ reconstructedImages
  }, ImageSize -> 600,
    PlotLabel -> Style["Autoencoder: Original (top) vs Reconstructed (bottom)",
      14, Bold, FontFamily -> "Palatino"]
  ];
  Export["reconstructions.png", reconstructionComparison, ImageResolution -> 200];,
  (* else *)
  Print["  WARNING: Autoencoder training returned $Failed\n"];
];


(* -------------------------------------------------------------------------- *)
(* MOVEMENT IV: WEIGHT VISUALIZATION AS ART                                   *)
(* -------------------------------------------------------------------------- *)
(* The trained weights ARE the network's learned understanding of complex      *)
(* topology. We extract and visualize them as a final artistic statement:     *)
(* the machine's own painting of what it sees in our paintings.               *)
(* -------------------------------------------------------------------------- *)

Print["═══════════════════════════════════════════════════"];
Print["  MOVEMENT IV: Weight Visualization"];
Print["═══════════════════════════════════════════════════"];

(* Guard: only proceed if classifier trained successfully *)
If[Head[trainedClassifier] =!= NetChain,
  Print["  SKIPPED — classifier did not train. Check Movement III errors."];
  Goto["Finale"];
];

(* --- Extract Classifier Weights --- *)
layerNames = Keys[NetInformation[trainedClassifier, "Layers"]];

(* Extract convolution layer indices *)
convLayers = Select[
  Range[Length[layerNames]],
  MatchQ[NetExtract[trainedClassifier, #], _ConvolutionLayer] &
];

Print["  Found " <> ToString[Length[convLayers]] <> " convolutional layers"];

(* --- Visualize First Layer Filters (most interpretable) --- *)
firstConvWeights = Normal[NetExtract[trainedClassifier, {convLayers[[1]], "Weights"}]];
numFilters = Length[firstConvWeights];

firstLayerViz = GraphicsGrid[
  Partition[
    Table[
      Labeled[
        Image[Rescale[Mean[firstConvWeights[[i]]]], ImageSize -> 80],
        "f" <> ToString[i],
        Bottom
      ],
      {i, numFilters}
    ],
    UpTo[8]
  ],
  ImageSize -> 800,
  PlotLabel -> Style["Layer 1 Learned Filters — Raw Topology Detectors",
    16, Bold, FontFamily -> "Palatino"],
  Spacings -> {5, 5}
];

(* --- Layer 2 Filter Correlation Matrix --- *)
If[Length[convLayers] >= 2,
  secondConvWeights = Normal[NetExtract[trainedClassifier, {convLayers[[2]], "Weights"}]];
  flatFilters = Flatten[#] & /@ secondConvWeights;
  correlationMatrix = Outer[CosineDistance, flatFilters, flatFilters, 1];

  filterCorrelationPlot = MatrixPlot[
    1 - correlationMatrix,
    ColorFunction -> "ThermometerColors",
    PlotLabel -> Style["Layer 2 Filter Correlations\n(Learned Topological Relationships)",
      14, Bold, FontFamily -> "Palatino"],
    FrameLabel -> {"Filter Index", "Filter Index"},
    ImageSize -> 500
  ];
];

(* --- Weight Distribution Histogram --- *)
allWeights = {};
layerCounter = 0;

Do[
  If[MatchQ[NetExtract[trainedClassifier, i],
      _ConvolutionLayer | _LinearLayer],
    layerCounter++;
    w = Flatten[Normal[NetExtract[trainedClassifier, {i, "Weights"}]]];
    allWeights = Join[allWeights, w];
  ],
  {i, Length[layerNames]}
];

weightDistPlot = Histogram[
  allWeights,
  100,
  "PDF",
  PlotLabel -> Style["Weight Distribution — The Network's Topology DNA",
    16, Bold, FontFamily -> "Palatino"],
  FrameLabel -> {"Weight Value", "Density"},
  Frame -> True,
  ChartStyle -> Directive[
    EdgeForm[None],
    Opacity[0.7],
    RGBColor[0.2, 0.4, 0.7]
  ],
  ImageSize -> 700,
  PlotRange -> {{-1, 1}, All},
  Filling -> Axis
];

(* --- The Grand Weight Painting --- *)
(* Each row = one layer's weights, padded to rectangular form.                *)
(* This is the network's self-portrait.                                       *)

layerWeightVectors = {};
Do[
  If[MatchQ[NetExtract[trainedClassifier, i],
      _ConvolutionLayer | _LinearLayer],
    w = Flatten[Normal[NetExtract[trainedClassifier, {i, "Weights"}]]];
    AppendTo[layerWeightVectors, w];
  ],
  {i, Length[layerNames]}
];

maxLen = Max[Length /@ layerWeightVectors];
paddedWeights = PadRight[#, maxLen, 0.0] & /@ layerWeightVectors;

grandWeightPainting = ArrayPlot[
  paddedWeights,
  ColorFunction -> (Blend[{
    RGBColor[0.05, 0.05, 0.2],   (* deep blue for negative *)
    RGBColor[0.1, 0.1, 0.3],
    RGBColor[0.95, 0.95, 0.9],   (* cream for zero *)
    RGBColor[0.8, 0.3, 0.1],
    RGBColor[0.6, 0.05, 0.05]    (* deep red for positive *)
  }, Rescale[#, {-0.5, 0.5}]] &),
  AspectRatio -> 1/4,
  ImageSize -> 1200,
  Frame -> True,
  FrameLabel -> {
    Style["Layer (Bottom to Top = Input to Output)", 12, FontFamily -> "Palatino"],
    Style["Weight Index", 12, FontFamily -> "Palatino"]
  },
  PlotLabel -> Style[
    "The Network's Self-Portrait\nAll Learned Weights Visualized",
    20, Bold, FontFamily -> "Palatino"],
  PlotRangePadding -> None
];

Print["  Grand Weight Painting complete"];

(* --- Autoencoder Latent Space (if trained) --- *)
If[Head[trainedAutoencoder] === NetChain,
  Print["  Computing latent space visualization..."];
  trainedEncoder = NetExtract[trainedAutoencoder, 1];

  sampleSize = Min[300, Length[trainingPatches]];
  SeedRandom[99];
  sampleIdx = RandomSample[Range[Length[trainingPatches]], sampleSize];
  samplePatchesForLatent = trainingPatches[[sampleIdx]];
  sampleLabelsForLatent = trainingLabels[[sampleIdx]];

  latentVectors = Flatten[Normal[trainedEncoder[#]]] & /@ samplePatchesForLatent;

  tsneCoords = DimensionReduce[latentVectors, 2, Method -> "TSNE"];

  labelColors = AssociationThread[
    validLabels,
    ColorData["Rainbow"] /@ Subdivide[0, 1, Max[Length[validLabels] - 1, 1]]
  ];

  tsnePoints = MapThread[
    {Opacity[0.6], labelColors[#2], PointSize[0.01], Point[#1]} &,
    {tsneCoords, sampleLabelsForLatent}
  ];

  latentSpacePlot = Graphics[
    tsnePoints,
    PlotLabel -> Style[
      "Latent Space — t-SNE of Autoencoder Bottleneck\nClusters = Learned Topological Families",
      16, Bold, FontFamily -> "Palatino"],
    Frame -> True,
    FrameLabel -> {"t-SNE 1", "t-SNE 2"},
    ImageSize -> 700,
    Epilog -> {
      Inset[
        SwatchLegend[Values[labelColors], Keys[labelColors],
          LegendLayout -> "Column",
          LabelStyle -> {10, FontFamily -> "Palatino"}],
        Scaled[{0.85, 0.75}]
      ]
    }
  ];

  Print["  Latent space visualization complete"];

  (* Autoencoder first-layer filters *)
  aeFirstWeights = Normal[NetExtract[trainedAutoencoder, {1, 1, "Weights"}]];
  numAEFilters = Length[aeFirstWeights];

  aeFilterViz = GraphicsGrid[
    Partition[
      Table[
        Image[Rescale[Mean[aeFirstWeights[[i]]]], ImageSize -> 60],
        {i, numAEFilters}
      ],
      UpTo[8]
    ],
    ImageSize -> 600,
    PlotLabel -> Style["Autoencoder — Learned Input Features",
      14, Bold, FontFamily -> "Palatino"],
    Spacings -> {3, 3}
  ];,
  (* else — no autoencoder *)
  Print["  Autoencoder not available — skipping latent space visualization"];
  latentSpacePlot = Graphics[Text["Autoencoder did not train"]];
  aeFilterViz = Graphics[Text["N/A"]];
];


(* -------------------------------------------------------------------------- *)
(* FINALE: EXPORT THE COMPLETE WORK                                           *)
(* -------------------------------------------------------------------------- *)
Label["Finale"];

Print["\n═══════════════════════════════════════════════════"];
Print["  FINALE: Assembling & Exporting"];
Print["═══════════════════════════════════════════════════"];

(* Export all major visualizations — guard each with Head check *)
safeExport[file_, expr_] := If[Head[expr] =!= Graphics && Head[expr] =!= GraphicsGrid
    && Head[expr] =!= Legended && Head[expr] =!= ArrayPlot,
  Print["  SKIP export: " <> file <> " (not a valid graphic)"],
  Export[file, expr, ImageResolution -> 200];
  Print["  Exported: " <> file]
];

safeExport["weight_painting.png", grandWeightPainting];
safeExport["latent_space.png", latentSpacePlot];
safeExport["confusion_matrix.png", confusionPlot];
safeExport["weight_distribution.png", weightDistPlot];
safeExport["first_layer_filters.png", firstLayerViz];
safeExport["ae_filters.png", aeFilterViz];
If[ValueQ[filterCorrelationPlot],
  safeExport["filter_correlations.png", filterCorrelationPlot]
];

Print["\n  ═══ COMPLETE ═══"];
Print["  Movement I:   5 complex paintings created"];
Print["  Movement II:  12+ filters & convolutions applied"];
Print["  Movement III: Classifier + Autoencoder trained"];
Print["  Movement IV:  Weight visualizations rendered"];

Print["\n  \"The complex plane is the canvas."];
Print["   Analytic continuation is the brush."];
Print["   Convolution reveals what was hidden."];
Print["   The neural network paints what it sees.\""];
Print[""];
Print["  — A Topological Painting, 2026"];
