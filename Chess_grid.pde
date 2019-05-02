int rect_val = 12;
int tmpS;
int tmpFlgC;
Square[][] squares = new Square[rect_val][rect_val];
Grid grid;
void setupGrid() {
  grid = new Grid();
}
  //size(360, 360, P3D);
  //background(255);
class Grid{
  Grid(){
  
  tmpS = width / rect_val;

  for (int i = 0; i < rect_val; i++) {
    for (int j = 0; j < rect_val; j++) {
      if (i % 2 == 0 && j % 2 == 0 ||
        i % 2 != 0 && j % 2 != 0) {
        tmpFlgC = 1;
      } else {
        tmpFlgC = 0;
      }
      squares[i][j] = new Square(i*tmpS, j*tmpS, tmpS, tmpFlgC);
    }
  }
  }

  void draw() {
    noStroke();
    rotateX(radians(50));
  
    for (int i = 0; i < rect_val; i++) {
      for (int j = 0; j < rect_val; j++) {
        squares[i][j].drawingRect();
        squares[i][j].move();
      }
    }
  }
}
