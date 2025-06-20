function getTimePeriod(date = new Date()) {
  const hours = date.getHours();

  if (hours >= 5 && hours < 12) {
    return "blue"; // Morning to before noon
  }
  else if (hours >= 12 && hours < 17) {
    return "noon"; // Noon to afternoon
  } 
  else {
    return "dark"; // Evening to early morning
  }
}

export default getTimePeriod;