class Square {
  int x;
  int y;
  int s;
  
  int spd = 3;
  int flgC;
  color c;
  Square(int tmpX, int tmpY, int tmpS, int tmpFlgC) {
    x = tmpX;
    y = tmpY;
    s = tmpS;

    flgC = tmpFlgC;
  }

  void drawingRect() {
    colorMode(HSB,360,90,90);
    if (flgC == 1) {
      int m = (audio.averageSpecs.length - 1);
     // c = getBright(colors.colorMap(1,1,m));
         //   color c = colors.colorMap(1,3,m);
      //fill(3, 88, 255);
     // c = dimColor(c, 200);
     if (c >= 360) c=0; else c++;
      fill(c,90,90);
      stroke(3, 8, 255);
    } else {
      fill(colors.background);
      stroke(0);
    }
    rect(x, y, s, s);
    colorMode(RGB,255,255,255);
  }

  void move() {
    y -= spd;

    if (y < -s) {
      y = height-s;
    }
  }
}
