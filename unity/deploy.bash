#!/bin/bash

SCRIPT_DIR="`readlink -f $(dirname $0)`"
SDL_BASE="`readlink -f ${SCRIPT_DIR}/..`"
DEPLOY="${SDL_BASE}/deploy"
echo "Base is ${SDL_BASE}"
echo "Deploying to ${DEPLOY}"

# Sanity check
if test "x${SDL_BASE}" = 'x' || test "x${SDL_BASE}" = 'x/'; then
	echo "Error determining SDL base, abort!"
	exit 1
fi

# Clean slate
rm -rf "${DEPLOY}"
mkdir -p "${DEPLOY}"

# Extra files for wayland backend
cp unity/wayland/*.h "${SDL_BASE}/include"
cp -R unity/wayland/xkbcommon "${SDL_BASE}/include"
cp -R unity/wayland/EGL "${SDL_BASE}/include"
cp unity/wayland/generated/*.h "${SDL_BASE}/include"
cp unity/wayland/generated/*.c "${SDL_BASE}/src"

# Copy includes
echo "Deploying includes"
cp -R "${SDL_BASE}/include" "${DEPLOY}/"
# TODO: Mechanism for updating non-linux config headers
CONFIG_HEADER="${DEPLOY}/include/SDL_config.h"
for platform in linux32 linux64; do
	platform_include="${DEPLOY}/include/${platform}"
	mkdir -p "${platform_include}"
	cp "${CONFIG_HEADER}" "${platform_include}/"
done
rm -f "${CONFIG_HEADER}"

# Copy source
echo "Copying source"
for source in `cat "${SCRIPT_DIR}/sources.list"`; do
	source_dir="${DEPLOY}/`dirname ${source}`"
	mkdir -p "${source_dir}"
	cp "${SDL_BASE}/${source}" "${source_dir}"
	header=`echo "${source}" | sed 's/\.c$/.h/'`
	if test -e "${SDL_BASE}/${header}"; then
		cp "${SDL_BASE}/${header}" "${source_dir}"
	fi
	cheader=`echo "${source}" | sed 's/\.c$/_c.h/'`
	if test -e "${SDL_BASE}/${cheader}"; then
		cp "${SDL_BASE}/${cheader}" "${source_dir}"
	fi
done

# Write license information
cp "${SDL_BASE}/unity/LICENSE.txt" "${DEPLOY}"
cat "${SDL_BASE}/COPYING.txt" >> "${DEPLOY}/LICENSE.txt"
cat "${SDL_BASE}/unity/wayland/COPYING.txt" >> "${DEPLOY}/LICENSE.txt"

# Generate jamfiles
echo "Generating jamfiles"

# Strip trailing newline, indent/quote/comma-separate
SOURCES=`head -n -1 "${SCRIPT_DIR}/sources.list" | sed 's/.*/                "&",/'`

JAMFILE="${DEPLOY}/SDL2_sources.jam.cs"
echo '' > "${JAMFILE}"
echo 'using JamSharp.Runtime;' >> "${JAMFILE}"
echo '' >> "${JAMFILE}"
echo 'namespace External.SDL2' >> "${JAMFILE}"
echo '{' >> "${JAMFILE}"
echo '    class SDL2_sources' >> "${JAMFILE}"
echo '    {' >> "${JAMFILE}"
echo '        internal static JamList GetSDLSources()' >> "${JAMFILE}"
echo '        {' >> "${JAMFILE}"
echo '            return new JamList(' >> "${JAMFILE}"

# Strip trailing comma from last entry
echo "${SOURCES:0:-1}" >> "${JAMFILE}"

echo '            );' >> "${JAMFILE}"
echo '        }' >> "${JAMFILE}"
echo '    }' >> "${JAMFILE}"
echo '}' >> "${JAMFILE}"
