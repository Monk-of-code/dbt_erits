

---

## **1️⃣ Set up Python and virtual environment**

```powershell
# Windows PowerShell
python -m venv venv
.\venv\Scripts\Activate.ps1
```

```bash
# Linux/macOS
python3 -m venv venv
source venv/bin/activate
```

---

## **2️⃣ Install dependencies**

```bash
pip install -r requirements.txt
```

* This ensures dbt and any other project packages are installed in your environment.

---

## **3️⃣ Point dbt to the project-local `profiles.yml`**

Set the environment variable `DBT_PROFILES_DIR` to your `.dbt` folder inside the repo:

### Windows PowerShell:

```powershell
$env:DBT_PROFILES_DIR = "$(pwd)/.dbt"
```

### Linux/macOS:

```bash
export DBT_PROFILES_DIR=$(pwd)/.dbt
```

* This tells dbt to use the `profiles.yml` shipped with the repo rather than `~/.dbt/profiles.yml`.

---

## **4️⃣ Verify dbt configuration**
To be run in erits folder

```bash
dbt debug
```

* Checks that dbt can find `profiles.yml`, connect to the database, and access the target schema.

---

## **5️⃣ Run dbt models**

```bash
dbt run
```

* Executes all models in the project using the repo’s `profiles.yml`.

### Optional:

* Run specific models:

```bash
dbt run --select my_model
```


