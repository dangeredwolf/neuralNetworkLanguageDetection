// note to self: in atom ctrl+alt+b = start sketch, ctrl+alt+c = stop

boolean processing3 = true;

Brain brain;

String[] languages = {
  "Random",   // 0
  "Key Mash", // 1
  "English",  // 2
  "Spanish",  // 3
  "French",   // 4
  "German",   // 5
  "Japanese", // 6
  "Swahili",  // 7
  "Mandarin", // 8
  "Esperanto",// 9
  "Dutch",    // 10
  "Polish",   // 11
  "Lojban"    // 12
};

int[] countedLanguages = {3, 1};

float STARTING_AXON_VARIABILITY = 1.0;
float WINDOW_SCALE_SIZE = 0.5;

int SAMPLE_LENGTH = 15;
int INPUTS_PER_CHAR = 27;
int INPUT_LAYER_HEIGHT = INPUTS_PER_CHAR*SAMPLE_LENGTH+1;
int LANGUAGE_COUNT = languages.length; // no more manually changing this :)
int MIDDLE_LAYER_NEURON_COUNT = 19;
int MINIMUM_WORD_LENGTH = 5;
int OUTPUT_LAYER_HEIGHT = LANGUAGE_COUNT+1;
int TRAINS_PER_FRAME = 1000;

int frameRate = 120;

PFont regularFont;
PFont boldFont;

String word = "-";
String windowText = "Cary's Language Neutral Network (Updated by @dangeredwolf)";

String[][] trainingData = new String[LANGUAGE_COUNT][];
int[] langSizes = new int[LANGUAGE_COUNT];

int bestStreak = 0;
int streak = 0;
int iteration = 0;
int lineAt = 0;
int desiredOutput = 0;
int recentRightCount = 0;
int lastPressedKey = -1;
int guessWindow = 1000;

boolean[] recentGuesses = new boolean[guessWindow];

boolean training = false;
boolean typing = false;
boolean stopOnError = false;
boolean stopTraining = false;
boolean lastOneWasCorrect = false;

void setup() {

  for (int i = 0; i < LANGUAGE_COUNT; i++) {

    trainingData[i] = loadStrings("output" + i + ".txt");
    String s = trainingData[i][trainingData[i].length-1];

    langSizes[i] = Integer.parseInt(s.substring(s.indexOf(",")+1, s.length()));

  }

  for (int i = 0; i < guessWindow; i++)
    recentGuesses[i] = false;

  regularFont = loadFont("SegoeUI-Semibold-48.vlw");
  boldFont = loadFont("SegoeUI-Bold-48.vlw");

  int[] bls = {INPUT_LAYER_HEIGHT, MIDDLE_LAYER_NEURON_COUNT, OUTPUT_LAYER_HEIGHT};
  brain = new Brain(bls, INPUTS_PER_CHAR, languages);
  int SIZEX = (int)(WINDOW_SCALE_SIZE * 1920);
  int SIZEY = (int)(WINDOW_SCALE_SIZE * 1080);

  size(960, 540);

  if (processing3) {

    size(960, 540);
    surface.setResizable(true);
    surface.setSize(SIZEX, SIZEY);
    surface.setResizable(false);
    surface.setTitle(windowText);

  } else {
    size(SIZEX, SIZEY);
    frame.setTitle(windowText);
  }

  frameRate(frameRate);

}

void subText(String t, int x, int y, boolean f) {
  if (f)
    fill(128);
  textFont(regularFont, 36);
  text(t, x, y);
}

void subText(String t, int x, int y) {
  subText(t, x, y, true);
}

void mainText(String t, int x, int y, boolean f) {
  if (f)
    fill(0);
  textFont(boldFont, 48);
  text(t, x, y);
}

void mainText(String t, int x, int y) {
  mainText(t, x, y, true);
}

void draw() {

  scale(WINDOW_SCALE_SIZE);
  smooth(1);

  if (keyPressed) {

    int c = (int)(key);

    if (c != lastPressedKey) {

      switch(c) {
        case 8:
          training = false;

          if (typing && word.length() >= 1)
            word = word.substring(0, word.length()-1);

          typing = true;
          getBrainErrorFromLine(word, 0, false);
          break;
        case 49:
          training = !training;
          typing = false;
          break;
        case 50:
          training = false;
          typing = false;
          train();
          break;
        case 51:
          brain.alpha *= 0.5;
          break;
        case 52:
          brain.alpha *= 2;
          break;
        case 53:
          stopOnError = !stopOnError;
          stopTraining = false;
          break;

        default:

        if (c >= 97 && c <= 122) {

          if (!typing)
            word = "";

          training = false;
          typing = true;
          word = (word+(char)(c)).toUpperCase();

          getBrainErrorFromLine(word, 0, false);

        }
      }

    }

    lastPressedKey = c;

  } else
    lastPressedKey = -1;

  if (training) {

    for (int i = 0; i < TRAINS_PER_FRAME; i++) {

      if (stopTraining) {
        stopTraining = false;
        training = false;
        return;
      }

      train();

    }

  }

  background(255); // White background
  textAlign(LEFT);

  subText("Iteration", 20, 50); // Iteration Label
  mainText(iteration+"", 200, 55); // Iteration Value
  subText("Input", 20, 150); // Input Label

  // Input Value
  fill(0, 120, 255);
  mainText(word, 130, 153, false);

  subText("Output", 20, 250);

  String o = languages[desiredOutput];

  if (typing)
    o = "Input";

  // Output Value
  fill(0, 120, 255);
  mainText(o, 155, 255, false);

  subText("Step", 20, 350);
  mainText(nf((float)(brain.alpha), 0, 4), 120, 355);
  subText("Min Length", 20, 450);
  mainText(MINIMUM_WORD_LENGTH+"", 220, 457);

  for (int i = 0; i < countedLanguages.length; i++)
    text(languages[countedLanguages[i]], 20, 1020-i*55);

  subText("Languages", 20, 1000-countedLanguages.length*55);

  int ex = 1330;
  subText("Prediction", ex, 55);
  String s = "";

  fill(0, 120, 255);

  mainText(languages[brain.topOutput], ex+190, 60, false);

  if (typing) {
    s = "Did I get it?";
    fill(160, 120, 0);
  } else {
    if (lastOneWasCorrect) {
      s = "Correct";
      fill(20, 140, 50);
    } else {
      s = "Incorrect";
      fill(220, 20, 20);
    }
  }

  mainText(s, ex, 150, false);

  if (brain.confidence > .75)
    fill(20, 140, 50);
  else if (brain.confidence > .25)
    fill(180, 180, 20);
  else
    fill(220, 20, 20);

  textFont(boldFont, 36);
  text(percentify(brain.confidence)+" Confident", ex, 200);

  subText("Correct of Last "+guessWindow+" Guesses", ex, 290);
  mainText(percentify(((float)recentRightCount) / min(iteration, guessWindow)), ex, 350);
  subText("Current Streak", ex, 430);
  mainText(streak+"", ex, 480);
  subText("Best Streak", ex, 530);
  mainText(bestStreak+"", ex, 580);

  textFont(boldFont, 36);
  text("Keyboard Shortcuts", ex, 740);


  textFont(regularFont, 36);
  fill(128);

  if (training)
    fill(0);

  if (stopOnError)
    text("1) Train Until Incorrect", ex, 800);
  else
    text("1) Toggle Training", ex, 800);

  fill(128);

  text("2) Perform one Training", ex, 850);
  text("3) Decrease Step Size", ex, 900);
  text("4) Increase Step Size", ex, 950);

  if (stopOnError)
    fill(0);
  text("5) Stop at Incorrect", ex, 1000);

  translate(550, 40);
  brain.drawBrain(55);
  lineAt++;

}

void train() {
  int lang = countedLanguages[(int)(random(0, countedLanguages.length))];  //(int)(random(0, LANGUAGE_COUNT));
  word = "";

  while(word.length() < MINIMUM_WORD_LENGTH) {

    lineAt = binarySearch(lang, (int)(random(0, langSizes[lang])));
    String[] parts = trainingData[lang][lineAt].split(",");
    word = parts[0];

  }

  desiredOutput = lang;

  double error = getBrainErrorFromLine(word, desiredOutput, true); // ignore "not used" error

  if (brain.topOutput == desiredOutput) {

    if (!recentGuesses[iteration%guessWindow])
      recentRightCount++;

    recentGuesses[iteration%guessWindow] = true;
    lastOneWasCorrect = true;
    streak++;

    if (streak > bestStreak)
      bestStreak = streak;

  } else {

    if (recentGuesses[iteration%guessWindow])
      recentRightCount--;

    recentGuesses[iteration%guessWindow] = false;
    lastOneWasCorrect = false;

    if (stopOnError)
      stopTraining = true;

    streak = 0;
  }

}

int binarySearch(int lang, int n) {
  return binarySearch(lang, n, 0, trainingData[lang].length - 1);
}

int binarySearch(int lang, int n, int beg, int end) {

  if (beg > end)
    return beg;

  int mid = (beg+end)/2;
  String s = trainingData[lang][mid];
  int diff = n-Integer.parseInt(s.substring(s.lastIndexOf(",")+1, s.length()));

  if (diff == 0)
    return mid + 1;
  else if (diff > 0)
    return binarySearch(lang, n, mid + 1, end);
  else if (diff < 0)
    return binarySearch(lang, n, beg, mid - 1);

  return -1;

}

String percentify(double d) {
  return nf((float)(d * 100), 0, 2)+"%";
}

double getBrainErrorFromLine(String word, int desiredOutput, boolean train) {
  double inputs[] = new double[INPUT_LAYER_HEIGHT];

  for (int i = 0; i < INPUT_LAYER_HEIGHT; i++)
    inputs[i] = 0;

  for (int i = 0; i < SAMPLE_LENGTH; i++) {

    int c = 0;

    if (i < word.length())
      c = (int)word.toUpperCase().charAt(i) - 64;

    c = max(0, c);
    inputs[i * INPUTS_PER_CHAR + c] = 1;

  }

  double desiredOutputs[] = new double[OUTPUT_LAYER_HEIGHT];

  for (int i = 0; i < OUTPUT_LAYER_HEIGHT; i++)
    desiredOutputs[i] = 0;

  desiredOutputs[desiredOutput] = 1;

  if (train)
    iteration++;

  return brain.useBrainGetError(inputs, desiredOutputs, train);

}
