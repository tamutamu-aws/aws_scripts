BEGIN{
  at_once="false";
}

{
  if (at_once=="false" && $0 ~ /^JAVA_OPTS="/) {
    print gensub(/(^JAVA_OPTS=")(.*$)/, "\\1-Djenkins.install.runSetupWizard=false \\2", "g");
    at_once="true";
    next
  }

  {
    print $0;
  }
}
