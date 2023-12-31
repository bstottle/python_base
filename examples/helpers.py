import torch

def get_device():
    if torch.cuda.is_available(): # Oddly, CUDA _or_ AMD ROCm
        return torch.device("cuda")
    elif torch.has_mps:  # For Apple Silicon
        return torch.device("mps")
    else:
        return torch.device("cpu")

def device_info():
    if torch.cuda.is_available(): # Oddly, CUDA _or_ AMD ROCm
        print("Using CUDA")
        for i in range(torch.cuda.device_count()):
            total_memory = torch.cuda.get_device_properties(i).total_memory
            name = torch.cuda.get_device_name(i)
            print(f"  Device #{i}: Name {name} VRAM {bytes2human(total_memory)}")
    elif torch.has_mps:  # For Apple Silicon
        # TODO more useful info to show?
        print("Using MPS (Metal Performance Shaders)")
    else:
        print("No available GPU, running on CPU only")

def bytes2human(number: int, decimal_unit: bool = True) -> str:
    """Convert number of bytes in a human readable string.

    >>> bytes2human(10000, True)
    '10.00 KB'
    >>> bytes2human(10000, False)
    '9.77 KiB'

    Args:
        number (int): Number of bytes
        decimal_unit (bool): If specified, use 1 kB (kilobyte)=10^3 bytes.
            Otherwise, use 1 KiB (kibibyte)=1024 bytes

    Returns:
        str: Bytes converted in readable string
    """
    symbols = ['K', 'M', 'G', 'T', 'P', 'E', 'Z', 'Y']
    symbol_values = [(symbol,
                      1000**(i+1) if decimal_unit else (1 << (i+1) * 10))
                     for i, symbol in enumerate(symbols)]

    for symbol, value in reversed(symbol_values):
        if number >= value:
            suffix = "B" if decimal_unit else "iB"
            return f"{float(number)/value:.2f}{symbol}{suffix}"

    return f"{number} B"