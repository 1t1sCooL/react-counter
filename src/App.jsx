import React, {useState} from 'react';

function App() {
  const [count, setCount] = useState(0);
  return (
    <div className="App">
      <div>
        <button id='back' onClick={()=>window.history.back()}>Назад</button>
        <h2>Счетчик:</h2>
        <h1>{count}</h1>
        <button className="minus" onClick={()=>setCount(count-1)}>- Минус</button>
        <button className="plus" onClick={()=>setCount(count+1)}>Плюс +</button>
      </div>
    </div>
  );
}

export default App;
