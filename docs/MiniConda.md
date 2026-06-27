# Miniconda Setup Guide for Machine Learning Projects

A complete guide for setting up Miniconda and using Jupyter notebooks in VSCode for machine learning projects on Ubuntu.

---

## Table of Contents
1. [Initial Setup](#initial-setup)
2. [Creating Your First ML Environment](#creating-your-first-ml-environment)
3. [Setting Up VSCode](#setting-up-vscode)
4. [Working with Existing Projects](#working-with-existing-projects)
5. [Creating New Projects](#creating-new-projects)
6. [Daily Workflow](#daily-workflow)
7. [Useful Commands](#useful-commands)
8. [Troubleshooting](#troubleshooting)

---

## Initial Setup

### 1. Miniconda Installation
During installation, when asked:
```
Proceed with initialization? [yes|no]
```
**Answer: `no`** (since you don't use conda often)

### 2. Create Conda Activation Alias (Optional but Recommended)
Add this to your `~/.zshrc` file:
```bash
alias startconda='eval "$(~/miniconda3/bin/conda shell.zsh hook)"'
```

Reload your shell:
```bash
source ~/.zshrc
```

Now you can activate conda anytime with just:
```bash
startconda
```

---

## Creating Your First ML Environment

### Step 1: Activate Conda
```bash
eval "$(~/miniconda3/bin/conda shell.zsh hook)"
# or if you set up the alias:
startconda
```

You should see `(base)` appear in your prompt.

### Step 2: Create ML Environment
```bash
conda create -n ml_project python=3.11
```
- `-n ml_project` = name of your environment (you can use any name)
- `python=3.11` = Python version

Press `y` when prompted.

### Step 3: Activate Your Environment
```bash
conda activate ml_project
```

Your prompt should change from `(base)` to `(ml_project)`.

### Step 4: Install Essential Packages
```bash
# Jupyter support (required for .ipynb files)
conda install jupyter ipykernel

# Essential ML packages
conda install numpy pandas matplotlib seaborn scikit-learn

# Deep Learning (choose one or both)
conda install pytorch torchvision -c pytorch
# or
conda install tensorflow
```

### Step 5: Register Kernel for VSCode
```bash
python -m ipykernel install --user --name=ml_project --display-name "Python (ml_project)"
```

This allows VSCode to see and use your environment.

---

## Setting Up VSCode

### 1. Install Required Extensions
Open VSCode and install:
- **Python** (by Microsoft)
- **Jupyter** (by Microsoft)

**How to install:**
1. Press `Ctrl + Shift + X`
2. Search for "Python" and install
3. Search for "Jupyter" and install

### 2. Verify Setup
- Open any `.ipynb` file
- Click "Select Kernel" in the top-right corner
- Click "Python Environments..."
- You should see `ml_project` in the list

---

## Working with Existing Projects

### Clone and Setup Existing Project from GitHub

```bash
# 1. Clone the project
cd ~  # or your preferred location
git clone https://github.com/username/your-project.git
cd your-project

# 2. Activate conda and your environment
startconda  # or use the full eval command
conda activate ml_project

# 3. Install project dependencies
# If there's a requirements.txt:
pip install -r requirements.txt

# If there's an environment.yml:
conda env create -f environment.yml

# 4. Open in VSCode
code .
```

### Select Environment in VSCode

**For Jupyter Notebooks (.ipynb):**
1. Open any `.ipynb` file
2. Click "Select Kernel" (top-right corner)
3. Choose "Python Environments..."
4. Select `Python 3.11.x ('ml_project')`

**For Python Scripts (.py):**
1. Open any `.py` file
2. Click the Python version (bottom-right corner)
3. Select `Python 3.11.x ('ml_project')`

### Run Your Code

**In Notebooks:**
- Click ▶️ play button next to a cell
- Or press `Shift + Enter` to run and move to next cell
- Or press `Ctrl + Enter` to run and stay on current cell

**In Python Scripts:**
- Right-click → "Run Python File in Terminal"
- Or press `F5` to debug

---

## Creating New Projects

### Step 1: Create Project Structure
```bash
# Create project folder
mkdir my_new_ml_project
cd my_new_ml_project

# Initialize git (optional)
git init
```

### Step 2: Create New Environment (if needed)
```bash
startconda
conda create -n my_new_project python=3.11
conda activate my_new_project
```

### Step 3: Install Packages
```bash
conda install jupyter ipykernel numpy pandas matplotlib scikit-learn
python -m ipykernel install --user --name=my_new_project
```

### Step 4: Create Notebook
```bash
# Open VSCode
code .

# In VSCode:
# Method 1: Ctrl + Shift + P → "Create: New Jupyter Notebook"
# Method 2: Right-click → New File → name it "notebook.ipynb"
```

### Step 5: Select Kernel and Start Coding
- Click "Select Kernel" (top-right)
- Choose "Python Environments..."
- Select your environment
- Start coding!

---

## Daily Workflow

### Starting Your Work Session
```bash
# 1. Navigate to project
cd ~/your-project

# 2. Activate conda
startconda

# 3. Activate your environment
conda activate ml_project

# 4. Open VSCode
code .

# 5. In VSCode: Select your kernel (if not already selected)
```

### Ending Your Work Session
```bash
# Close VSCode, then in terminal:
conda deactivate
```

---

## Useful Commands

### Environment Management
```bash
# List all environments
conda env list

# Create new environment
conda create -n env_name python=3.11

# Activate environment
conda activate env_name

# Deactivate environment
conda deactivate

# Delete environment
conda env remove -n env_name
```

### Package Management
```bash
# Install package
conda install package_name

# Install multiple packages
conda install numpy pandas matplotlib

# Install from pip (if not available in conda)
pip install package_name

# List installed packages
conda list

# Update package
conda update package_name

# Remove package
conda remove package_name
```

### Jupyter Kernel Management
```bash
# List all Jupyter kernels
jupyter kernelspec list

# Install kernel
python -m ipykernel install --user --name=env_name

# Remove kernel
jupyter kernelspec uninstall env_name
```

### Export and Share Environments
```bash
# Export to requirements.txt (pip)
pip freeze > requirements.txt

# Export to environment.yml (conda)
conda env export > environment.yml

# Create environment from file
conda env create -f environment.yml
pip install -r requirements.txt
```

---

## Troubleshooting

### Issue: Can't see my environment in VSCode

**Solution 1: Restart VSCode**
```bash
# Close VSCode completely, then reopen
code .
```

**Solution 2: Reinstall kernel**
```bash
conda activate ml_project
python -m ipykernel install --user --name=ml_project
```

**Solution 3: Check extensions**
- Make sure Python and Jupyter extensions are installed
- Restart VSCode after installing

---

### Issue: "Module not found" error

**Solution: Make sure package is installed in the correct environment**
```bash
# Activate your environment
conda activate ml_project

# Check if package is installed
conda list | grep package_name

# If not, install it
conda install package_name
```

---

### Issue: Kernel keeps dying/crashing

**Solution 1: Check for package conflicts**
```bash
conda activate ml_project
conda update --all
```

**Solution 2: Create fresh environment**
```bash
conda deactivate
conda env remove -n ml_project
conda create -n ml_project python=3.11
conda activate ml_project
# Reinstall packages
```

---

### Issue: Conda command not found

**Solution: Activate conda first**
```bash
eval "$(~/miniconda3/bin/conda shell.zsh hook)"
# or
startconda
```

---

## Key Concepts Summary

### Anaconda vs Miniconda
- **Miniconda**: Minimal (50MB), install only what you need
- **Anaconda**: Full package (3GB), 250+ pre-installed packages
- **You chose Miniconda** ✓ - Better for terminal users!

### What is an Environment?
- Isolated workspace for each project
- Each has its own Python version and packages
- Prevents conflicts between projects

### What does `ipykernel install` do?
- Registers your conda environment with Jupyter
- **Does NOT create a new environment**
- Just makes it visible to VSCode/Jupyter

### Python Environments vs Jupyter Kernel
- Both options in VSCode work the same
- "Python Environments..." = Direct access to conda environments
- "Jupyter Kernel..." = Access to registered kernels
- **Use either one** - both work fine!

---

## Quick Reference Card

```bash
# Daily routine
cd ~/project
startconda
conda activate ml_project
code .

# Install package
conda install package_name

# Create new environment
conda create -n new_env python=3.11

# List environments
conda env list

# Deactivate
conda deactivate
```

---

## Additional Resources

- Conda documentation: https://docs.conda.io/
- VSCode Python tutorial: https://code.visualstudio.com/docs/python/python-tutorial
- Jupyter in VSCode: https://code.visualstudio.com/docs/datascience/jupyter-notebooks

---

**Happy coding! 🚀**