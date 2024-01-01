# File: gpu_monitor.py

import ipywidgets as widgets
import subprocess
import threading
import time
import torch

class GPUMonitor:
    def __init__(self, interval=1):
        self.interval = interval
        # TODO allow difference metrics (would need difference output format as well)
        self.data_points = "memory.used,utilization.gpu"
        self.should_stop = False
        self.thread = threading.Thread(target=self.update_widget, daemon=True)
        self.gpu_usage_widget = widgets.Label(value="Initializing...")
        self.toggle_button = widgets.Button(description="Stop Updates")
        self.toggle_button.on_click(self.on_toggle_button_clicked)
        self.total_memory = int(torch.cuda.get_device_properties(0).total_memory/1e6) # in MB
        # If there are any errors, this will show the trace as the cell output
        self.set_gpu_widget()
        self.thread.start()

    def get_gpu_stats(self):
        result = subprocess.check_output(['nvidia-smi', f'--query-gpu={self.data_points}', '--format=csv,nounits,noheader'])
        return [int(param.strip()) for param in result.decode('utf-8').split(',')]

    def set_gpu_widget(self):
            mem_usage, gpu_usage = self.get_gpu_stats()
            mem_string = f"{int(mem_usage/self.total_memory*100)}% (of {self.total_memory} MB)"
            time_string = time.strftime("%H:%M:%S")
            self.gpu_usage_widget.value = f"GPU Stats: Memory Used = {mem_string}, GPU Used: {gpu_usage}%,  Time: {time_string}"
        
    def update_widget(self):
        while not self.should_stop:
            self.set_gpu_widget()
            time.sleep(self.interval)

    def on_toggle_button_clicked(self, b):
        if self.thread.is_alive():
            self.should_stop = True
            self.gpu_usage_widget.value = ""
            self.toggle_button.description = "Start Updates"
        else:
            self.should_stop = False
            self.thread = threading.Thread(target=self.update_widget, daemon=True)
            self.thread.start()
            self.toggle_button.description = "Stop Updates"

    def display(self):
        return widgets.HBox([self.toggle_button, self.gpu_usage_widget])
