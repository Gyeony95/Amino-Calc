final aminoMap = {
  'G': 75.03,
  'A': 89.05,
  'S': 105.04,
  'T': 119.06,
  'C': 121.02,
  'V': 117.08,
  'L': 131.09,
  'I': 131.09,
  'M': 149.05,
  'P': 115.06,
  'F': 165.08,
  'Y': 181.07,
  'W': 204.09,
  'D': 133.04,
  'E': 147.05,
  'N': 132.05,
  'Q': 146.07,
  'H': 155.07,
  'K': 146.11,
  'R': 174.11,
};

void main(){
  const String value = 'CFCWCMT';

  var splitList = value.split('');
  double  result = splitList.fold(0.0, (sum, e) => sum + (aminoMap[e] ?? 0));
  print(result);
}