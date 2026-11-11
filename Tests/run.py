# Comprobaciones fuera del juego con Lua 5.1 (como el cliente), desde la raiz del addon:
#   uv run --no-project --with lupa python -I Tests/run.py
# 1) compila todos los .lua del addon, 2) ejecuta Tests/engine.lua.
import glob, sys
import lupa.lua51 as lupa

lua = lupa.LuaRuntime(unpack_returned_tuples=True)
lua.execute("arg = {}")

bad = 0
for path in sorted(glob.glob("**/*.lua", recursive=True)):
    result = lua.globals().loadfile(path)  # funcion si compila; (nil, error) si no
    if isinstance(result, tuple):
        print(result[1])
        bad += 1
print("SYNTAX OK" if bad == 0 else f"{bad} ficheros con errores")
if bad:
    sys.exit(1)

# brain.lua termina con os.exit(0 | 1)
lua.execute(open("Tests/engine.lua", encoding="utf-8").read())
