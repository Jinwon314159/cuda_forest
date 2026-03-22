# cuda_forest

## External large assets (Google Drive)

Large `.warehouse` files are stored externally (not in Git).

- `harvest/model/trees.warehouse`  
  https://drive.google.com/file/d/16px659Yi_f4xCMaPp7ycbbsfYbVlmVtx/view?usp=sharing
- `harvest/model/_trees_90.warehouse`  
  https://drive.google.com/file/d/16iRfsEtfnXyJgMzqnV-keBujfMCAyys_/view?usp=sharing
- `data_renamed/test/trees.warehouse`  
  https://drive.google.com/file/d/18lPKjIJ7LRJt2MEScFa1tF-KNub_p2rP/view?usp=sharing

### Download helper

Use:

```bash
bash scripts/fetch_warehouse.sh
```

By default this script uses `gdown` (recommended). Install with:

```bash
pip install gdown
```
