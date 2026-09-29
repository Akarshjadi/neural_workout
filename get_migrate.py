with open("lib/data/app_database.dart") as f:
    lines = f.readlines()
    for i, line in enumerate(lines):
        if "_migrateV6ToV7" in line:
            print("".join(lines[i:i+30]))
            break
