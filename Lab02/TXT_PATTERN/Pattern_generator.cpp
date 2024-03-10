#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <algorithm>
using namespace std;
const int ROWS = 8;
const int COLS = 8;
int customAsciiToNumber(char c);
void shiftMatrix(int A[][COLS], int shift);
void rotateMarix(int B[][COLS], int rot);
int number_line = 0;
int main() {
    std::ofstream outFile1("rotor_A.txt");
    std::ofstream outFile2("rotor_B.txt");
    std::ofstream outFile3("input_str.txt");
    std::ofstream outFile4("output_str.txt");
    std::ifstream inFile("string.txt");
    bool map[8][8] = { false };
    int A[8][8];
    bool map2[8][8] = { false };
    int B[8][8];

    //srand(time(NULL)); // 使用時間作為隨機種子

    if (!inFile) {
        std::cerr << "無法打開文件." << std::endl;
        return 1;
    }

    std::string line;
    while (std::getline(inFile, line)) { // 逐行讀取文件內容
        number_line++;

        for (int i = 0; i < 64; i++) {
            int seed;
            do {
                seed = rand() % 64;
            } while (map[seed / 8][seed % 8]);

            map[seed / 8][seed % 8] = true;
            A[i / 8][i % 8] = seed;
        }



            for (int i = 0; i < 64; i++) {
                int seed;
                do {
                    seed = rand() % 64;
                } while (map2[seed / 8][seed % 8]);

                map2[seed / 8][seed % 8] = true;
                B[i / 8][i % 8] = seed;
            }



            // 將矩陣A寫入檔案rotor_A
            for (int i = 0; i < 8; i++) {
                for (int j = 0; j < 8; j++) {
                    outFile1 << A[i][j] << " ";
                }
            }
            outFile1 << std::endl;

            // 將矩陣B寫入檔案rotor_B
            for (int i = 0; i < 8; i++) {
                for (int j = 0; j < 8; j++) {
                    outFile2 << B[i][j] << " ";
                }

            }
            outFile2 << std::endl;

            std::string input = line;
            std::vector<std::string> tran;


            if (number_line <= 100)        outFile3 << 0 << " " << input.length() << " ";
            else outFile3 << 1 << " " << input.length() << " ";

            for (char c : input) { // 遍歷 input 中的每個字符
                int customAscii = customAsciiToNumber(c);
                tran.push_back(std::to_string(customAscii));
            }

            // 將tran寫入檔案 input_str or output_str
            if (number_line <= 100) {
                for (const std::string& num : tran) {
                    outFile3 << num << " ";
                }
                outFile3 << std::endl;
            }
            else {
                for (const std::string& num : tran) {
                    outFile4 << num << " ";
                }
                outFile4 << std::endl;
            }





            for (int i = 0; i < input.length(); i++) {
                int temp_A = A[std::stoi(tran[i]) / 8][std::stoi(tran[i]) % 8];
                int temp_B = B[temp_A / 8][temp_A % 8];
                int temp_rev = 63 - temp_B;
                int temp_B_rev;
                int temp_A_rev = 0;
                for (int j = 0; j < 64; j++) {
                    if (temp_rev == B[j / 8][j % 8]) {
                        temp_B_rev = j;
                    }
                }
                for (int k = 0; k < 64; k++) {
                    if (temp_B_rev == A[k / 8][k % 8]) {
                        temp_A_rev = k;
                    }
                }

                if (number_line <= 100)            outFile4 << temp_A_rev << " ";
                else  outFile3 << temp_A_rev << " ";

                //shift A
                int shift = temp_A % 4;
                shiftMatrix(A, shift);
                //rotate B
                int rot = temp_B % 8;
                rotateMarix(B, rot);
            }

            for (int i = 0; i < 8; i++) {
                for (int j = 0; j < 8; j++) {
                    map[i][j] = { false };
                    map2[i][j] = { false };
                }
            }

            if (number_line <= 50)        outFile4 << endl;
            else outFile3 << endl;



        }
        std::cout << number_line << endl;




        outFile1.close();
        outFile2.close();
        outFile3.close();
        outFile4.close();
        inFile.close(); // 關閉文件
        return 0;
    }

    void shiftMatrix(int A[][COLS], int shift) {
        // 將矩陣A往右移動shift次
        //shift %= COLS; // 確保shift在0~COLS之間
        int temp[8];



        for (int s = 0; s < shift; ++s) {
            for (int k = 0; k < 8; k++) {
                temp[k] = A[k][7];
            }
            for (int i = 0; i < ROWS; ++i) {
                int temp = A[i][COLS - 1];
                for (int j = COLS - 1; j > 0; --j) {
                    A[i][j] = A[i][j - 1];
                }
            }
            for (int i = 1; i < 8; i++) {
                A[i][0] = temp[i - 1];
            }
            A[0][0] = temp[7];
        }
    }
    int customAsciiToNumber(char c) {
        switch (c) {
        case 'a': return 0;
        case 'b': return 1;
        case 'c': return 2;
        case 'd': return 3;
        case 'e': return 4;
        case 'f': return 5;
        case 'g': return 6;
        case 'h': return 7;
        case 'i': return 8;
        case 'j': return 9;
        case 'k': return 10;
        case 'l': return 11;
        case 'm': return 12;
        case 'n': return 13;
        case 'o': return 14;
        case 'p': return 15;
        case 'q': return 16;
        case 'r': return 17;
        case 's': return 18;
        case 't': return 19;
        case 'u': return 20;
        case 'v': return 21;
        case 'w': return 22;
        case 'x': return 23;
        case 'y': return 24;
        case 'z': return 25;
        case ' ': return 26;
        case '?': return 27;
        case ',': return 28;
        case '-': return 29;
        case '.': return 30;
        case '\n': return 31;
        case 'A': return 32;
        case 'B': return 33;
        case 'C': return 34;
        case 'D': return 35;
        case 'E': return 36;
        case 'F': return 37;
        case 'G': return 38;
        case 'H': return 39;
        case 'I': return 40;
        case 'J': return 41;
        case 'K': return 42;
        case 'L': return 43;
        case 'M': return 44;
        case 'N': return 45;
        case 'O': return 46;
        case 'P': return 47;
        case 'Q': return 48;
        case 'R': return 49;
        case 'S': return 50;
        case 'T': return 51;
        case 'U': return 52;
        case 'V': return 53;
        case 'W': return 54;
        case 'X': return 55;
        case 'Y': return 56;
        case 'Z': return 57;
        case ':': return 58;
        case '#': return 59;
        case ';': return 60;
        case '_': return 61;
        case '+': return 62;
        case '&': return 63;
        default: return -1;
        }
    }
    void rotateMarix(int B[][COLS], int rot) {
        if (rot == 1) {
            for (int i = 0; i < ROWS; i++) {
                for (int j = 0; j < COLS; j += 2) {
                    int temp = B[i][j];
                    B[i][j] = B[i][j + 1];
                    B[i][j + 1] = temp;
                }
            }
        }
        else if (rot == 2) {
            for (int i = 0; i < ROWS; i++) {
                int temp1 = B[i][2];
                B[i][2] = B[i][0];
                B[i][0] = temp1;

                int temp2 = B[i][3];
                B[i][3] = B[i][1];
                B[i][1] = temp2;

                int temp3 = B[i][4];
                B[i][4] = B[i][6];
                B[i][6] = temp3;

                int temp4 = B[i][5];
                B[i][5] = B[i][7];
                B[i][7] = temp4;
            }
        }
        else if (rot == 3) {
            for (int i = 0; i < ROWS; i++) {
                int temp = B[i][4];
                B[i][4] = B[i][1];
                B[i][1] = temp;

                int temp1 = B[i][5];
                B[i][5] = B[i][2];
                B[i][2] = temp1;

                int temp2 = B[i][6];
                B[i][6] = B[i][3];
                B[i][3] = temp2;

            }
        }
        else if (rot == 4) {
            for (int i = 0; i < ROWS; i++) {
                for (int j = 0; j < 4; j++) {
                    int temp = B[i][j + 4];
                    B[i][j + 4] = B[i][j];
                    B[i][j] = temp;
                }
            }
        }

        else if (rot == 5) {
            for (int i = 0; i < ROWS; i++) {
                for (int j = 0; j < 3; j++) {
                    int temp = B[i][j + 5];
                    B[i][j + 5] = B[i][j];
                    B[i][j] = temp;
                }
            }
        }
        else if (rot == 6) {
            for (int i = 0; i < ROWS; i++) {
                for (int j = 0; j < 2; j++) {
                    int temp = B[i][j + 6];
                    B[i][j + 6] = B[i][j];
                    B[i][j] = temp;
                }
                int temp1 = B[i][3];
                B[i][3] = B[i][2];
                B[i][2] = temp1;
                int temp2 = B[i][5];
                B[i][5] = B[i][4];
                B[i][4] = temp2;
            }
        }
        else if (rot == 7) {
            for (int i = 0; i < ROWS; i++) {
                for (int j = 0; j < 4; j++) {
                    int temp = B[i][7 - j];
                    B[i][7 - j] = B[i][j];
                    B[i][j] = temp;
                }
            }
        }
        else  B = B;
    }
