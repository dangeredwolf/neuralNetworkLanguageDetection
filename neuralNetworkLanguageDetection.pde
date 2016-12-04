float WINDOW_SCALE_SIZE = 0.5;
int MINIMUM_WORD_LENGTH = 5;
float STARTING_AXON_VARIABILITY = 1.0;
int TRAINS_PER_FRAME = 1000;
PFont font;
PFont font2;
Brain brain;
int LANGUAGE_COUNT = 13;
int MIDDLE_LAYER_NEURON_COUNT = 19;
String[][] trainingData = new String[LANGUAGE_COUNT][];
int SAMPLE_LENGTH = 15;
int INPUTS_PER_CHAR = 27;
int INPUT_LAYER_HEIGHT = INPUTS_PER_CHAR*SAMPLE_LENGTH+1;
int OUTPUT_LAYER_HEIGHT = LANGUAGE_COUNT+1;
int lineAt = 0;
int iteration = 0;
int guessWindow = 1000;
boolean[] recentGuesses = new boolean[guessWindow];
int recentRightCount = 0;
boolean training = false;
String word = "-";
int desiredOutput = 0;
int lastPressedKey = -1;
boolean typing = false;
boolean stopOnError = false;
boolean stopTraining = false;
int[] countedLanguages = {3,1};
boolean lastOneWasCorrect = false;
String[] languages = {"Random","Key Mash","English","Spanish","French","German","Japanese",
"Swahili","Mandarin","Esperanto","Dutch","Polish","Lojban"};
int[] langSizes = new int[LANGUAGE_COUNT];
void setup(){
  for(int i = 0; i < LANGUAGE_COUNT; i++){
    trainingData[i] = loadStrings("output"+i+".txt");
    String s = trainingData[i][trainingData[i].length-1];
    langSizes[i] = Integer.parseInt(s.substring(s.indexOf(",")+1,s.length()));
  }
  for(int i = 0; i < guessWindow; i++){
    recentGuesses[i] = false;
  }
  font = loadFont("SegoeUI-Semibold-48.vlw");
  font2 = loadFont("SegoeUI-Bold-48.vlw");
  int[] bls = {INPUT_LAYER_HEIGHT,MIDDLE_LAYER_NEURON_COUNT,OUTPUT_LAYER_HEIGHT};
  brain = new Brain(bls,INPUTS_PER_CHAR, languages);
  size(1000,580);
  frameRate(120);
}

void draw(){
  scale(WINDOW_SCALE_SIZE);
  if(keyPressed){
    int c = (int)(key);
    if(c == 49 && lastPressedKey != 49){
      training = !training;
      typing = false;
    }else if(c == 50 && lastPressedKey != 50){
      training = false;
      typing = false;
      train();
    }else if(c == 52 && lastPressedKey != 52){
      brain.alpha *= 2;
    }else if(c == 53 && lastPressedKey != 53){
      stopOnError = !stopOnError;
      stopTraining = false;
    }else if(c == 51 && lastPressedKey != 51){
      brain.alpha *= 0.5;
    }else if(c >= 97 && c <= 122 && !(lastPressedKey >= 97 && lastPressedKey <= 122)){
      training = false;
      if(!typing){
        word = "";
      }
      typing = true;
      word = (word+(char)(c)).toUpperCase();
      getBrainErrorFromLine(word,0,false);
    }else if(c == 8 && lastPressedKey != 8){
      training = false;
      if(typing && word.length() >= 1){
        word = word.substring(0,word.length()-1);
      }
      typing = true;
      getBrainErrorFromLine(word,0,false);
    }
    lastPressedKey = c;
  }else{
    lastPressedKey = -1;
  }
  if(training){
    for(int i = 0; i < TRAINS_PER_FRAME; i++){
      if (stopTraining) {
        stopTraining = false;
        training = false;
        return;
      }
      train();
    }
  }
  background(255);
  fill(0);
  textFont(font2,36);
  textAlign(LEFT);
  text("Language Neural Network",20,50);
  fill(128);
  textFont(font,36);
  text("Iteration",20,150);
  textFont(font2,48);
  fill(0);
  text(iteration,200,155);
  fill(128);
  textFont(font,36);
  text("Input",20,250);
  textFont(font2,48);
  fill(0,120,255);
  text(word,130,253);
  fill(128);
  textFont(font,36);
  text("Output",20,350);
  String o = languages[desiredOutput];
  if(typing){
    o = "Input";
  }
  fill(0,120,255);
  textFont(font2,48);
  text(o,155,355);
  fill(128);
  textFont(font,36);
  text("Step",20,450);
  textFont(font2,48);
  fill(0);
  text(nf((float)(brain.alpha),0,4),120,455);
  fill(128);
  textFont(font,36);
  text("Min Length",20,550);
  fill(0);
  textFont(font2,48);
  text(MINIMUM_WORD_LENGTH,220,557);
  for(int i = 0; i < countedLanguages.length; i++){
    text(languages[countedLanguages[i]],20,1130-i*55);
  }
  fill(128);
  textFont(font,36);
  text("Languages",20,1100-countedLanguages.length*55);


  int ex = 1330;
  text("Prediction",ex,55);
  String s = "";

  textFont(font2,48);
  fill(0,120,255);

  text(languages[brain.topOutput],ex+190,60);

   if(typing){
    s = "Did I get it?";
    fill(160,120,0);
  }else{
    if(lastOneWasCorrect){
      s = "Correct";
      fill(20,140,50);
    }else{
      s = "Incorrect";
      fill(220,20,20);
    }
  }

  text(s,ex,150);
  textFont(font2,36);
  if (brain.confidence > .75) {
    fill(20,140,50);
  } else if (brain.confidence > .25) {
    fill(180,180,20);
  } else {
    fill(220,20,20);
  }

  text(percentify(brain.confidence)+" Confident",ex,200);
  fill(128);

  textFont(font,36);
  text("Correct of Last "+guessWindow+" Guesses",ex,290);
  textFont(font2,48);
  fill(0);
  text(percentify(((float)recentRightCount)/min(iteration,guessWindow)),ex,350);

  textFont(font2,36);

  text("Keyboard Shortcuts",ex,840);


  textFont(font,36);
  fill(128);
  
  if (training) {
    fill(0);
  }
  if (stopOnError) {
    text("1) Train Until Incorrect",ex,900);
  } else {
    text("1) Toggle Training",ex,900);
  }
  fill(128);
  text("2) Perform one Training",ex,950);
  text("3) Decrease Step Size",ex,1000);
  text("4) Increase Step Size",ex,1050);
  if (stopOnError) {
    fill(0);
  }
  text("5) Stop at Incorrect",ex,1100);
  fill(128); // neutralise it basically

  translate(550,40);
  brain.drawBrain(55);
  lineAt++;
}
void train(){
  int lang = countedLanguages[(int)(random(0,countedLanguages.length))];//(int)(random(0,LANGUAGE_COUNT));
  word = "";
  while(word.length() < MINIMUM_WORD_LENGTH){
    int wordIndex = (int)(random(0,langSizes[lang]));
    lineAt = binarySearch(lang, wordIndex);
    String[] parts = trainingData[lang][lineAt].split(",");
    word = parts[0];
  }
  desiredOutput = lang;//Integer.parseInt(parts[1]);
  double error = getBrainErrorFromLine(word,desiredOutput,true);
  if(brain.topOutput == desiredOutput){
    if(!recentGuesses[iteration%guessWindow]){
      recentRightCount++;
    }
    recentGuesses[iteration%guessWindow] = true;
    lastOneWasCorrect = true;
  }else{
    if(recentGuesses[iteration%guessWindow]){
      recentRightCount--;
    }
    recentGuesses[iteration%guessWindow] = false;
    lastOneWasCorrect = false;
    if (stopOnError) {
      stopTraining = true;
    }
  }
}
int binarySearch(int lang, int n){
  return binarySearch(lang,n,0,trainingData[lang].length-1);
}
int binarySearch(int lang, int n, int beg, int end){
  if(beg > end){
    return beg;
  }
  int mid = (beg+end)/2;

  String s = trainingData[lang][mid];
  int diff = n-Integer.parseInt(s.substring(s.lastIndexOf(",")+1,s.length()));
  if(diff == 0){
    return mid+1;
  }else if(diff > 0){
    return binarySearch(lang,n,mid+1,end);
  }else if(diff < 0){
    return binarySearch(lang,n,beg,mid-1);
  }
  return -1;
}
String percentify(double d){
  return nf((float)(d*100),0,2)+"%";
}
double getBrainErrorFromLine(String word, int desiredOutput, boolean train){
  double inputs[] = new double[INPUT_LAYER_HEIGHT];
  for(int i = 0; i < INPUT_LAYER_HEIGHT; i++){
    inputs[i] = 0;
  }
  for(int i = 0; i < SAMPLE_LENGTH; i++){
    int c = 0;
    if(i < word.length()){
      c = (int)word.toUpperCase().charAt(i)-64;
    }
    c = max(0,c);
    inputs[i*INPUTS_PER_CHAR+c] = 1;
  }
  double desiredOutputs[] = new double[OUTPUT_LAYER_HEIGHT];
  for(int i = 0; i < OUTPUT_LAYER_HEIGHT; i++){
    desiredOutputs[i] = 0;
  }
  desiredOutputs[desiredOutput] = 1;
  if(train){
    iteration++;
  }
  return brain.useBrainGetError(inputs, desiredOutputs,train);
}