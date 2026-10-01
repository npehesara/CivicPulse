import React, { useRef } from 'react';
import { useFrame } from '@react-three/fiber';
import { OrbitControls, Line } from '@react-three/drei';
import * as THREE from 'three';

export const TerritoryMap: React.FC = () => {
  const groupRef = useRef<THREE.Group>(null);
  const nodes: [number, number, number][] = [
    [0, 0, 0], [1.5, 0.5, -1], [-1, 1, 0.5], [0.5, -1, 1.5], [-1.5, -0.5, -0.5]
  ];

  useFrame(({ clock }) => {
    if (groupRef.current) {
      groupRef.current.rotation.y = Math.sin(clock.getElapsedTime() * 0.1) * 0.2;
    }
  });

  return (
    <>
      <ambientLight intensity={0.2} />
      <directionalLight position={[5, 10, 5]} intensity={1.5} color="#22D3EE" />
      <pointLight position={[0, -5, 0]} intensity={1} color="#6C5CE7" />

      <OrbitControls 
        enablePan={false} 
        enableZoom={true} 
        minDistance={3} 
        maxDistance={10} 
        autoRotate 
        autoRotateSpeed={0.5}
      />

      <group ref={groupRef}>
        {/* Abstract Terrain Grid Placeholder */}
        <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, -1, 0]}>
          <planeGeometry args={[10, 10, 20, 20]} />
          <meshBasicMaterial color="#22D3EE" wireframe transparent opacity={0.1} />
        </mesh>

        {/* Territory Nodes */}
        {nodes.map((pos, i) => (
          <mesh key={i} position={pos as [number, number, number]}>
            <octahedronGeometry args={[0.15, 0]} />
            <meshStandardMaterial color={i === 0 ? "#FB7185" : "#22D3EE"} emissive={i === 0 ? "#FB7185" : "#22D3EE"} emissiveIntensity={2} />
          </mesh>
        ))}

        {/* Connections */}
        <Line points={[nodes[0], nodes[1]]} color="#22D3EE" opacity={0.3} transparent />
        <Line points={[nodes[0], nodes[2]]} color="#22D3EE" opacity={0.3} transparent />
        <Line points={[nodes[0], nodes[3]]} color="#22D3EE" opacity={0.3} transparent />
        <Line points={[nodes[2], nodes[4]]} color="#22D3EE" opacity={0.3} transparent />

        {/* Pulse Ring at Center */}
        <mesh position={[0, -0.9, 0]} rotation={[-Math.PI / 2, 0, 0]}>
          <ringGeometry args={[0.5, 0.55, 32]} />
          <meshBasicMaterial color="#FB7185" transparent opacity={0.5} />
        </mesh>
      </group>
    </>
  );
};
