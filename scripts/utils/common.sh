### common:r_echo [message]
common:r_echo() {
  local readonly _ESC="\e["
  local readonly _ESCEND=m
  local readonly _COLOR_OFF="${_ESC}${_ESCEND}"

  # Red
  echo -en "${_ESC}31${_ESCEND}"
  echo "${1}"
  echo -en "${_COLOR_OFF}"
}


### common:m_echo [message]
common:m_echo() {
  local readonly _ESC="\e["
  local readonly _ESCEND=m
  local readonly _COLOR_OFF="${_ESC}${_ESCEND}"

  # Magenta
  echo -en "${_ESC}35${_ESCEND}"
  echo "${1}"
  echo -en "${_COLOR_OFF}"
}
