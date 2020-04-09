import os
import seaborn as sns
import pandas as pd
import matplotlib.pyplot as plt
import traceback
sns.set()

def plot(dirname):
    exp_name = os.path.basename(dirname)
    exp_log_f = os.path.join(dirname, "exp.log")

    for e in os.scandir(dirname):
        if not e.is_dir():
            continue
        sweep_dump_dir = os.path.join(e.path, "sweep_dump")
        
        if not os.path.exists(sweep_dump_dir):
            continue
        for f_e in os.scandir(sweep_dump_dir):
            
            if not f_e.name[:5] == "sweep":
                continue
            name = f_e.name
            if "sweep_rx_" in name:
                exp_type = "receiver"
            elif "sweep_tx_" in name:
                exp_type = "sender"
            else:
                print("Receiver/Sender?")
                print(name)
                exit()
            tmp = name
            tmp = tmp[tmp.index("-")+1:]
            exp_no = int(tmp[:tmp.index("_")])
            tmp = tmp[tmp.index("-")+1:]
            exp_distance = int(tmp[:tmp.index(".")])
            
            
            new_name = name[:name.rindex(".")]
            tofile = os.path.join(dirname, new_name+".pdf")
            tofile_png = os.path.join(dirname, new_name+".png")

            print(exp_type)
            print(exp_no)
            print(exp_distance)
            try:
                df = pd.read_csv(f_e.path, delimiter=";")
                
                for index, row in df.iterrows():
                    if row["src"] == "00:00:00:00:00:00":
                        df.drop(index, inplace=True)
                if df.empty:
                    continue
                #print(data)
                
                ax = sns.boxplot(x="sec", y="snr_db", data=df)
                ax.set_ylim(0, 45)
                ax.set(xlabel='Sector', ylabel='SNR in dB')
                ax.set_title('SNR of {} for distance {} (Experiment number: {})'.format(exp_type, exp_distance, exp_no))
                
                fig = ax.get_figure()
                fig.set_size_inches(11.7, 8.27)
                fig.savefig(tofile) 
                fig.savefig(tofile_png) 
                plt.clf()
            except Exception:
                traceback.print_exc()
            #plt.show()
            
            
            
            
    
    
    print(exp_name)

def list_experiments(dirname):
    
    for e in os.scandir(dirname):
        if not e.is_dir():
            print("No dir: " + e.path)
            continue
        plot(e.path)
        



list_experiments("receiver")
list_experiments("sender")
