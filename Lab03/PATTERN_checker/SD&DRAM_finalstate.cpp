#include <fstream>
#include <iostream>
using namespace std;

const int number_SD = 65536;
const int number_DRAM = 8192;

int main()
{
    char **SD = new char *[number_SD];
    for (int i = 0; i < number_SD; ++i)
    {
        SD[i] = new char[17];
    }

    char **DRAM = new char *[number_DRAM];
    for (int i = 0; i < number_DRAM; ++i)
    {
        DRAM[i] = new char[17];
    }

    char **SD_final = new char *[number_SD];
    for (int i = 0; i < number_SD; ++i)
    {
        SD_final[i] = new char[17];
    }

    char **DRAM_final = new char *[number_DRAM];
    for (int i = 0; i < number_DRAM; ++i)
    {
        DRAM_final[i] = new char[17];
    }

    // 開檔
    ifstream DRAM_init("DRAM_init.dat");
    ifstream SD_init("SD_init.dat");
    ifstream Input("Input.txt");
    ifstream DRAM_final_file("DRAM_final.dat");
    ifstream SD_final_file("SD_final.dat");
    ofstream DRAM_golden("DRAM_golden.dat");
    ofstream SD_golden("SD_golden.dat");
    // initail
    for (int r = 0; r < number_DRAM; r++)
    {
        DRAM_init >> DRAM[r];
    }

    for (int r = 0; r < number_SD; r++)
    {
        SD_init >> SD[r];
    }
    // your result,final
    for (int r = 0; r < number_DRAM; r++)
    {
        DRAM_final_file >> DRAM_final[r];
    }
    for (int r = 0; r < number_SD; r++)
    {
        SD_final_file >> SD_final[r];
    }
    // 計算golden
    int direction, dram_pos, sd_pos, number;
    Input >> number;
    cout << "number of read write " << number << endl;
    while (Input >> direction >> dram_pos >> sd_pos)
    {
        if (direction == 0)
        {
            // 从DRAM写入到SD
            if (dram_pos >= 0 && dram_pos < number_DRAM && sd_pos >= 0 && sd_pos < number_SD)
            {
                for (int i = 0; i < 17; i++)
                {
                    SD[sd_pos][i] = DRAM[dram_pos][i];
                }
            }
            else
            {
                cerr << "Invalid position for DRAM or SRAM." << endl;
                return 1;
            }
        }
        else if (direction == 1)
        {
            // 从SD写入到DRAM
            if (dram_pos >= 0 && dram_pos < number_DRAM && sd_pos >= 0 && sd_pos < number_SD)
            {
                for (int i = 0; i < 17; i++)
                {
                    DRAM[dram_pos][i] = SD[sd_pos][i];
                }
            }
            else
            {
                cerr << "Invalid position for DRAM or SRAM." << endl;
                return 1;
            }
        }
        else
        {
            cerr << "Invalid direction. It should be either 0 or 1." << endl;
            return 1;
        }
    }
    // 比較golden 和 final
    bool dram_equal = true;
    for (int i = 0; i < number_DRAM; ++i)
    {
        for (int j = 0; j < 17; ++j)
        {
            if (DRAM[i][j] != DRAM_final[i][j])
            {
                cout << "DRAM different at" << i << endl;
                dram_equal = false;
                break;
            }
        }
        if (!dram_equal)
        {
            break;
        }
    }

    bool sd_equal = true;
    for (int i = 0; i < number_SD; ++i)
    {
        for (int j = 0; j < 17; ++j)
        {
            if (SD[i][j] != SD_final[i][j])
            {
                cout << "SD different at " << i << endl;
                sd_equal = false;
                break;
            }
        }
        if (!sd_equal)
        {
            break;
        }
    }
    if (dram_equal)
    {
        cout << "DRAM and DRAM_final are identical." << endl;
    }
    else
    {
        cout << "DRAM and DRAM_final are different." << endl;
    }

    if (sd_equal)
    {
        cout << "SD and SD_final are identical." << endl;
    }
    else
    {
        cout << "SD and SD_final are different." << endl;
    }
    /*
     for (int i = 0; i < number_DRAM; ++i)
     {
          DRAM_golden << DRAM[i] << endl;
     }

     for (int i = 0; i < number_SD; ++i)
     {
         SD_golden << SD[i] << endl;
     }
     */

    // 释放动态分配的内存

    for (int i = 0; i < number_SD; ++i)
    {
        delete[] SD[i];
    }
    delete[] SD;

    for (int i = 0; i < number_DRAM; ++i)
    {
        delete[] DRAM[i];
    }
    delete[] DRAM;

    for (int i = 0; i < number_SD; ++i)
    {
        delete[] SD_final[i];
    }
    delete[] SD_final;

    for (int i = 0; i < number_DRAM; ++i)
    {
        delete[] DRAM_final[i];
    }
    delete[] DRAM_final;

    DRAM_init.close();
    SD_init.close();
    DRAM_final_file.close();
    SD_final_file.close();
    Input.close();

    return 0;
}